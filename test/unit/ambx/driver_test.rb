require_relative "../../test_helper"

# A controllable stand-in for a real LIBUSB::DeviceHandle.
# Records every interrupt_transfer call for later inspection.
class FakeHandle
  attr_reader :transfers, :close_count

  def initialize
    @transfers = []
    @close_count = 0
  end

  def interrupt_transfer(**opts)
    @transfers << opts
    opts[:dataOut].bytesize
  end

  def claim_interface(_n)
    0
  end

  def auto_detach_kernel_driver=(_val)
    nil
  end

  def close
    @close_count += 1
  end
end

module DriverTestFixtures
  def fake_device_with(handle)
    device = Object.new
    device.define_singleton_method(:open) { handle }
    device
  end

  def fake_usb_device(vendor:, product:)
    device = Object.new
    device.define_singleton_method(:idVendor) { vendor }
    device.define_singleton_method(:idProduct) { product }
    device
  end

  def stub_context_with(devices)
    context = Object.new
    context.define_singleton_method(:devices) { devices }
    Ambx.instance_variable_set(:@context, context)
  end
end

describe "Ambx.open" do
  include AmbxTestHelpers
  include DriverTestFixtures

  before { reset_ambx! }

  it "returns true when all discovered device handles claim successfully" do
    handle = FakeHandle.new
    Ambx.instance_variable_set(:@devices, [ fake_device_with(handle) ])
    _(Ambx.open).must_equal true
  end

  it "returns false when interface claiming fails" do
    handle = FakeHandle.new
    handle.define_singleton_method(:claim_interface) { |_interface| nil }
    Ambx.instance_variable_set(:@devices, [ fake_device_with(handle) ])
    _(Ambx.open).must_equal false
  end
end

describe "Ambx.write with no available handles" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "returns nil when @handles is nil" do
    _(Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])).must_be_nil
  end

  it "returns nil when every handle in @handles is nil" do
    Ambx.instance_variable_set(:@handles, [ nil, nil ])
    _(Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])).must_be_nil
  end
end

describe "Ambx.write transfer behavior" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "sends a raw byte array to the handle as packed binary" do
    handle = FakeHandle.new
    bytes = [ 0xA1, Ambx::Lights::LEFT, 0x03, 255, 0, 0 ]
    Ambx.instance_variable_set(:@handles, [ handle ])

    Ambx.write(bytes)

    _(handle.transfers.length).must_equal 1
    _(handle.transfers.first[:dataOut]).must_equal bytes.pack("C*")
  end

  it "sends to the correct output endpoint" do
    handle = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ handle ])

    Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])

    _(handle.transfers.first[:endpoint]).must_equal Ambx::Protocol::ENDPOINT_OUT
  end
end

describe "Ambx.write packet and multi-handle behavior" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "accepts an Ambx::Packet and unwraps it transparently" do
    handle = FakeHandle.new
    packet = Ambx::Packet.set_color(Ambx::Lights::WWCENTER, 128, 64, 32)
    Ambx.instance_variable_set(:@handles, [ handle ])

    Ambx.write(packet)

    _(handle.transfers.first[:dataOut]).must_equal packet.to_a.pack("C*")
  end

  it "sends to all handles when multiple devices are present" do
    first = FakeHandle.new
    second = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ first, second ])

    Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])

    _(first.transfers.length).must_equal 1
    _(second.transfers.length).must_equal 1
  end
end

describe "Ambx.write with mixed handles and unplugged devices" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "skips nil handles in a mixed list" do
    handle = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ nil, handle, nil ])

    Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])

    _(handle.transfers.length).must_equal 1
  end

  it "calls close when a handle raises ENXIO during write" do
    handle = Object.new
    handle.define_singleton_method(:interrupt_transfer) { |**_| raise Errno::ENXIO }
    handle.define_singleton_method(:close) { nil }
    Ambx.instance_variable_set(:@handles, [ handle ])

    Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])

    _(Ambx.instance_variable_get(:@handles)).must_be_nil
  end
end

describe "Ambx.close basic behavior" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "returns nil when @handles is nil" do
    _(Ambx.close).must_be_nil
  end

  it "returns nil when every handle is nil" do
    Ambx.instance_variable_set(:@handles, [ nil ])
    _(Ambx.close).must_be_nil
  end
end

describe "Ambx.close cleanup behavior" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "calls close on each open handle" do
    first = FakeHandle.new
    second = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ first, second ])

    Ambx.close

    _(first.close_count).must_equal 1
    _(second.close_count).must_equal 1
  end

  it "resets @handles, @device and @devices after closing" do
    Ambx.instance_variable_set(:@handles, [ FakeHandle.new ])
    Ambx.instance_variable_set(:@device, Object.new)
    Ambx.instance_variable_set(:@devices, [ Object.new ])

    Ambx.close

    _(Ambx.instance_variable_get(:@handles)).must_be_nil
    _(Ambx.instance_variable_get(:@device)).must_be_nil
    _(Ambx.instance_variable_get(:@devices)).must_be_empty
  end
end

describe "Ambx.close when handles are already unplugged" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "tolerates ENXIO while closing a handle" do
    handle = Object.new
    handle.define_singleton_method(:close) { raise Errno::ENXIO }
    Ambx.instance_variable_set(:@handles, [ handle ])

    _ { Ambx.close }.must_be_silent
  end
end

describe "Ambx.close(true) light clearing" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "sends all-off packets for every light before closing" do
    handle = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ handle ])

    Ambx.close(true)

    _(handle.transfers.length).must_equal 5
    handle.transfers.each do |transfer|
      bytes = transfer[:dataOut].unpack("C*")
      _(bytes[3..5]).must_equal [ 0, 0, 0 ]
    end
  end

  it "uses the 0xA1-prefixed packet format for clear packets" do
    handle = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ handle ])

    Ambx.close(true)

    handle.transfers.each do |transfer|
      _(transfer[:dataOut].unpack("C*").first).must_equal 0xA1
    end
  end
end

describe "Ambx.close(true) with multiple handles" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "clears each handle exactly once when multiple handles are open" do
    first = FakeHandle.new
    second = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ first, second ])

    Ambx.close(true)

    _(first.transfers.length).must_equal 5
    _(second.transfers.length).must_equal 5
  end
end

describe "Ambx.reconnect! success and failure" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "returns true when connect and open succeed on the first try" do
    with_stub(Ambx, :connect, true) do
      with_stub(Ambx, :open, true) do
        _(Ambx.reconnect!(max_attempts: 3, delay: 0)).must_equal true
      end
    end
  end

  it "returns false when connect always fails" do
    with_stub(Ambx, :connect, false) do
      _(Ambx.reconnect!(max_attempts: 3, delay: 0)).must_equal false
    end
  end
end

describe "Ambx.reconnect! retry rules" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "returns false when open always fails" do
    with_stub(Ambx, :connect, true) do
      with_stub(Ambx, :open, false) do
        _(Ambx.reconnect!(max_attempts: 3, delay: 0)).must_equal false
      end
    end
  end

  it "retries exactly max_attempts times before giving up" do
    connect_calls = 0

    with_stub(Ambx, :connect, -> { connect_calls += 1; false }) do
      Ambx.reconnect!(max_attempts: 4, delay: 0)
    end

    _(connect_calls).must_equal 4
  end
end

describe "Ambx.reconnect! defaults and eventual success" do
  include AmbxTestHelpers

  before { reset_ambx! }

  it "succeeds on a later attempt when earlier ones fail" do
    attempt = 0

    with_stub(Ambx, :connect, -> { attempt += 1; attempt >= 2 }) do
      with_stub(Ambx, :open, true) do
        _(Ambx.reconnect!(max_attempts: 3, delay: 0)).must_equal true
      end
    end

    _(attempt).must_equal 2
  end

  it "defaults to 3 max_attempts" do
    connect_calls = 0

    with_stub(Ambx, :connect, -> { connect_calls += 1; false }) do
      Ambx.reconnect!(delay: 0)
    end

    _(connect_calls).must_equal 3
  end
end

describe "Ambx.connect device discovery" do
  include AmbxTestHelpers
  include DriverTestFixtures

  before { reset_ambx! }

  it "returns false when no amBX devices are present in the USB tree" do
    stub_context_with([])

    _(Ambx.connect).must_equal false
  end

  it "returns true when a matching built-in device is found" do
    device = fake_usb_device(vendor: Ambx::Protocol::USB_VENDOR_ID, product: Ambx::Protocol::USB_PRODUCT_ID)
    stub_context_with([ device ])

    _(Ambx.connect).must_equal true
  end
end

describe "Ambx.connect custom device ids and filtering" do
  include AmbxTestHelpers
  include DriverTestFixtures

  before { reset_ambx! }

  it "returns true for a device configured through AMBX_USB_DEVICE_IDS" do
    ENV["AMBX_USB_DEVICE_IDS"] = "1234:abcd"
    device = fake_usb_device(vendor: 0x1234, product: 0xABCD)
    stub_context_with([ device ])

    _(Ambx.connect).must_equal true
  ensure
    ENV.delete("AMBX_USB_DEVICE_IDS")
  end

  it "ignores devices with a different vendor ID" do
    device = fake_usb_device(vendor: 0xDEAD, product: Ambx::Protocol::USB_PRODUCT_ID)
    stub_context_with([ device ])

    _(Ambx.connect).must_equal false
  end
end

describe "Ambx.connect product filtering and context caching" do
  include AmbxTestHelpers
  include DriverTestFixtures

  before { reset_ambx! }

  it "ignores devices with a different product ID" do
    device = fake_usb_device(vendor: Ambx::Protocol::USB_VENDOR_ID, product: 0xBEEF)
    stub_context_with([ device ])

    _(Ambx.connect).must_equal false
  end

  it "reuses a cached LIBUSB::Context across multiple connect calls" do
    context_instances = 0
    stub_context_class = Class.new do
      define_method(:initialize) { context_instances += 1 }
      define_method(:devices) { [] }
    end

    original_context_class = LIBUSB.send(:remove_const, :Context)
    LIBUSB.const_set(:Context, stub_context_class)
    Ambx.instance_variable_set(:@context, nil)
    Ambx.connect
    Ambx.connect

    _(context_instances).must_equal 1
  ensure
    LIBUSB.send(:remove_const, :Context)
    LIBUSB.const_set(:Context, original_context_class)
  end
end
