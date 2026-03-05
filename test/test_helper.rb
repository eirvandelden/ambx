require "minitest/autorun"
require "minitest/spec"

begin
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
rescue LoadError
  # minitest-reporters not available; plain output
end

# ---------------------------------------------------------------------------
# LIBUSB stub — lets every test file run without a physical amBX device or
# the native libusb extension being loaded.  Individual test files that need
# finer-grained handle behaviour can define their own FakeHandle subclass.
# ---------------------------------------------------------------------------
module LIBUSB
  class Context
    def initialize; end

    def devices
      []
    end
  end

  class DeviceHandle
    def interrupt_transfer(**_opts); end
    def claim_interface(_n); end
    def auto_detach_kernel_driver=(_val); end
    def close; end
  end
end

# ---------------------------------------------------------------------------
# Require library files directly (bypasses libambx.rb which loads the real
# libusb gem) so pure-unit tests have no hardware dependency at all.
# ---------------------------------------------------------------------------
LIBPATH = File.expand_path("../libambx", __dir__)

require "#{LIBPATH}/data/protocoldefinitions"
require "#{LIBPATH}/data/lights"
require "#{LIBPATH}/data/fans"
require "#{LIBPATH}/data/rumbler"
require "#{LIBPATH}/ambx/packet"
require "#{LIBPATH}/communication/ambx"

# ---------------------------------------------------------------------------
# Shared helper — resets all Ambx class-level state between tests so no test
# can leak connection state into another.
# ---------------------------------------------------------------------------
module AmbxTestHelpers
  # Resets all Ambx class-level state so no test leaks USB context into another.
  def reset_ambx!
    Ambx.instance_variable_set(:@context, nil)
    Ambx.instance_variable_set(:@device,  nil)
    Ambx.instance_variable_set(:@devices, [])
    Ambx.instance_variable_set(:@handles, nil)
  end

  # Temporarily replaces a singleton method with a stub value or callable.
  # Restores the original even if the block raises.
  #
  # @example stub a return value
  #   with_stub(Ambx, :connect, false) { Ambx.reconnect! }
  # @example stub with a lambda (for call counting)
  #   with_stub(Ambx, :connect, -> { calls += 1; false }) { Ambx.reconnect! }
  def with_stub(object, method_name, value_or_callable, &block)
    original = object.singleton_method(method_name)
    callable = value_or_callable.respond_to?(:call) ? value_or_callable : ->(*) { value_or_callable }
    object.define_singleton_method(method_name, callable)
    block.call
  ensure
    object.define_singleton_method(method_name, original)
  end
end
