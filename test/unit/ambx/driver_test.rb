require_relative "../../test_helper"

# ---------------------------------------------------------------------------
# A controllable stand-in for a real LIBUSB::DeviceHandle.
# Records every interrupt_transfer call for later inspection.
# ---------------------------------------------------------------------------
class FakeHandle
  attr_reader :transfers, :close_count

  def initialize
    @transfers   = []
    @close_count = 0
  end

  def interrupt_transfer(**opts)
    @transfers << opts
    opts[:dataOut].bytesize
  end

  def claim_interface(_n); end
  def auto_detach_kernel_driver=(_val); end

  def close
    @close_count += 1
  end
end

# ---------------------------------------------------------------------------
describe Ambx do
  include AmbxTestHelpers

  before { reset_ambx! }

  # -------------------------------------------------------------------------
  describe ".write" do
    it "does nothing and returns nil when @handles is nil" do
      _(Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])).must_be_nil
    end

    it "does nothing when every handle in @handles is nil" do
      Ambx.instance_variable_set(:@handles, [ nil, nil ])
      _(Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])).must_be_nil
    end

    it "sends a raw byte array to the handle as packed binary" do
      handle = FakeHandle.new
      Ambx.instance_variable_set(:@handles, [ handle ])
      bytes = [ 0xA1, Ambx::Lights::LEFT, 0x03, 255, 0, 0 ]
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

    it "accepts an Ambx::Packet and unwraps it transparently" do
      handle = FakeHandle.new
      Ambx.instance_variable_set(:@handles, [ handle ])
      pkt = Ambx::Packet.set_color(Ambx::Lights::WWCENTER, 128, 64, 32)
      Ambx.write(pkt)
      _(handle.transfers.first[:dataOut]).must_equal pkt.to_a.pack("C*")
    end

    it "sends to all handles when multiple devices are present" do
      h1 = FakeHandle.new
      h2 = FakeHandle.new
      Ambx.instance_variable_set(:@handles, [ h1, h2 ])
      Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])
      _(h1.transfers.length).must_equal 1
      _(h2.transfers.length).must_equal 1
    end

    it "skips nil handles in a mixed list" do
      handle = FakeHandle.new
      Ambx.instance_variable_set(:@handles, [ nil, handle, nil ])
      Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])
      _(handle.transfers.length).must_equal 1
    end

    it "calls close when the handle raises ENXIO (device unplugged mid-write)" do
      bad_handle = Object.new
      bad_handle.define_singleton_method(:interrupt_transfer) { |**_| raise Errno::ENXIO }
      bad_handle.define_singleton_method(:close) { }
      Ambx.instance_variable_set(:@handles, [ bad_handle ])
      Ambx.write([ 0xA1, 0x0B, 0x03, 0, 0, 0 ])
      _(Ambx.instance_variable_get(:@handles)).must_be_nil
    end
  end

  # -------------------------------------------------------------------------
  describe ".close" do
    it "does nothing when @handles is nil" do
      _(Ambx.close).must_be_nil
    end

    it "does nothing when every handle is nil" do
      Ambx.instance_variable_set(:@handles, [ nil ])
      _(Ambx.close).must_be_nil
    end

    it "calls close on each open handle" do
      h1 = FakeHandle.new
      h2 = FakeHandle.new
      Ambx.instance_variable_set(:@handles, [ h1, h2 ])
      Ambx.close
      _(h1.close_count).must_equal 1
      _(h2.close_count).must_equal 1
    end

    it "resets @handles to nil afterwards" do
      Ambx.instance_variable_set(:@handles, [ FakeHandle.new ])
      Ambx.close
      _(Ambx.instance_variable_get(:@handles)).must_be_nil
    end

    it "resets @device to nil afterwards" do
      Ambx.instance_variable_set(:@handles, [ FakeHandle.new ])
      Ambx.instance_variable_set(:@device, Object.new)
      Ambx.close
      _(Ambx.instance_variable_get(:@device)).must_be_nil
    end

    it "resets @devices to an empty array afterwards" do
      Ambx.instance_variable_set(:@handles, [ FakeHandle.new ])
      Ambx.instance_variable_set(:@devices, [ Object.new ])
      Ambx.close
      _(Ambx.instance_variable_get(:@devices)).must_be_empty
    end

    it "tolerates ENXIO when closing a handle (device already unplugged)" do
      bad_handle = Object.new
      bad_handle.define_singleton_method(:close) { raise Errno::ENXIO }
      Ambx.instance_variable_set(:@handles, [ bad_handle ])
      _ { Ambx.close }.must_be_silent
    end

    describe "with clearLights: true" do
      it "sends all-off packets for every light before closing" do
        handle = FakeHandle.new
        Ambx.instance_variable_set(:@handles, [ handle ])
        Ambx.close(true)
        # LEFT, WWLEFT, WWCENTER, WWRIGHT, RIGHT => 5 packets
        _(handle.transfers.length).must_equal 5
        handle.transfers.each do |t|
          bytes = t[:dataOut].unpack("C*")
          _(bytes[3..5]).must_equal [ 0, 0, 0 ],
            "expected black packet, got #{bytes.map { |b| "0x%02X" % b }.inspect}"
        end
      end

      it "clears lights using the 0xA1-prefixed packet format" do
        handle = FakeHandle.new
        Ambx.instance_variable_set(:@handles, [ handle ])
        Ambx.close(true)
        handle.transfers.each do |t|
          _(t[:dataOut].unpack("C*")[0]).must_equal 0xA1
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  describe ".reconnect!" do
    it "returns true immediately when connect and open succeed on the first try" do
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

  # -------------------------------------------------------------------------
  describe ".connect" do
    it "returns false when no amBX devices are present in the USB tree" do
      fake_ctx = Object.new
      fake_ctx.define_singleton_method(:devices) { [] }
      Ambx.instance_variable_set(:@context, fake_ctx)
      _(Ambx.connect).must_equal false
    end

    it "returns true when a matching device is found" do
      fake_device = Object.new
      fake_device.define_singleton_method(:idVendor)  { Ambx::Protocol::USB_VENDOR_ID }
      fake_device.define_singleton_method(:idProduct) { Ambx::Protocol::USB_PRODUCT_ID }
      fake_ctx = Object.new
      fake_ctx.define_singleton_method(:devices) { [ fake_device ] }
      Ambx.instance_variable_set(:@context, fake_ctx)
      _(Ambx.connect).must_equal true
    end

    it "returns true for a device configured through AMBX_USB_DEVICE_IDS" do
      ENV["AMBX_USB_DEVICE_IDS"] = "1234:abcd"
      fake_device = Object.new
      fake_device.define_singleton_method(:idVendor)  { 0x1234 }
      fake_device.define_singleton_method(:idProduct) { 0xABCD }
      fake_ctx = Object.new
      fake_ctx.define_singleton_method(:devices) { [ fake_device ] }
      Ambx.instance_variable_set(:@context, fake_ctx)
      _(Ambx.connect).must_equal true
    ensure
      ENV.delete("AMBX_USB_DEVICE_IDS")
    end

    it "ignores devices with a different vendor ID" do
      fake_device = Object.new
      fake_device.define_singleton_method(:idVendor)  { 0xDEAD }
      fake_device.define_singleton_method(:idProduct) { Ambx::Protocol::USB_PRODUCT_ID }
      fake_ctx = Object.new
      fake_ctx.define_singleton_method(:devices) { [ fake_device ] }
      Ambx.instance_variable_set(:@context, fake_ctx)
      _(Ambx.connect).must_equal false
    end

    it "ignores devices with a different product ID" do
      fake_device = Object.new
      fake_device.define_singleton_method(:idVendor)  { Ambx::Protocol::USB_VENDOR_ID }
      fake_device.define_singleton_method(:idProduct) { 0xBEEF }
      fake_ctx = Object.new
      fake_ctx.define_singleton_method(:devices) { [ fake_device ] }
      Ambx.instance_variable_set(:@context, fake_ctx)
      _(Ambx.connect).must_equal false
    end

    it "reuses a cached LIBUSB::Context across multiple connect calls" do
      ctx_instances = 0
      stub_ctx = Class.new do
        define_method(:initialize) { ctx_instances += 1 }
        define_method(:devices)    { [] }
      end
      original_ctx_class = LIBUSB.send(:remove_const, :Context)
      LIBUSB.const_set(:Context, stub_ctx)
      Ambx.instance_variable_set(:@context, nil)
      Ambx.connect
      Ambx.connect
      _(ctx_instances).must_equal 1
    ensure
      LIBUSB.send(:remove_const, :Context)
      LIBUSB.const_set(:Context, original_ctx_class)
    end
  end
end
