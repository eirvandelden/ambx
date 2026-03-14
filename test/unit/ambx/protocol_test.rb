require_relative "../../test_helper"

describe Ambx::Protocol, "USB device identification" do
  it "has the correct vendor ID (Philips)" do
    _(Ambx::Protocol::USB_VENDOR_ID).must_equal 0x0471
  end

  it "has the correct product ID (amBX USB)" do
    _(Ambx::Protocol::USB_PRODUCT_ID).must_equal 0x083F
  end
end

describe Ambx::Protocol, "supported USB device IDs" do
  it "includes the default amBX USB IDs in the supported list" do
    ids = Ambx::Protocol.supported_usb_device_ids
    _(ids).must_include [ 0x0471, 0x083F ]
  end

  it "adds IDs from AMBX_USB_DEVICE_IDS to the supported list" do
    ENV["AMBX_USB_DEVICE_IDS"] = "1234:abcd,0x5678:0x9ABC"
    ids = Ambx::Protocol.supported_usb_device_ids
    _(ids).must_include [ 0x1234, 0xABCD ]
    _(ids).must_include [ 0x5678, 0x9ABC ]
  ensure
    ENV.delete("AMBX_USB_DEVICE_IDS")
  end
end

describe Ambx::Protocol, "supported USB device IDs from env parsing" do
  it "ignores malformed entries in AMBX_USB_DEVICE_IDS" do
    ENV["AMBX_USB_DEVICE_IDS"] = "1234:abcd,not-an-id,1234-ffff"
    default_ids = Ambx::Protocol::DEFAULT_USB_DEVICE_IDS
    ids = Ambx::Protocol.supported_usb_device_ids
    _(ids).must_include [ 0x1234, 0xABCD ]
    _(ids.length).must_equal default_ids.length + 1
  ensure
    ENV.delete("AMBX_USB_DEVICE_IDS")
  end

  it "accepts uppercase 0X prefixes in AMBX_USB_DEVICE_IDS" do
    ENV["AMBX_USB_DEVICE_IDS"] = "0X1234:0XABCD"
    ids = Ambx::Protocol.supported_usb_device_ids
    _(ids).must_include [ 0x1234, 0xABCD ]
  ensure
    ENV.delete("AMBX_USB_DEVICE_IDS")
  end
end

describe Ambx::Protocol, "USB endpoints" do
  it "has the correct input endpoint" do
    _(Ambx::Protocol::ENDPOINT_IN).must_equal 0x81
  end

  it "has the correct output endpoint" do
    _(Ambx::Protocol::ENDPOINT_OUT).must_equal 0x02
  end

  it "has the correct PnP notification endpoint" do
    _(Ambx::Protocol::ENDPOINT_PNP).must_equal 0x83
  end

  it "ENDPOINT_IN is an IN endpoint (bit 7 set)" do
    _(Ambx::Protocol::ENDPOINT_IN & 0x80).must_equal 0x80
  end

  it "ENDPOINT_OUT is an OUT endpoint (bit 7 clear)" do
    _(Ambx::Protocol::ENDPOINT_OUT & 0x80).must_equal 0
  end
end

describe Ambx::Protocol, "command opcodes" do
  it "has the correct SET_LIGHT_COLOR opcode" do
    _(Ambx::Protocol::SET_LIGHT_COLOR).must_equal 0x03
  end

  it "has the correct SET_TIMED_COLOR_SEQUENCE opcode" do
    _(Ambx::Protocol::SET_TIMED_COLOR_SEQUENCE).must_equal 0x72
  end

  it "SET_LIGHT_COLOR and SET_TIMED_COLOR_SEQUENCE are distinct" do
    _(Ambx::Protocol::SET_LIGHT_COLOR).wont_equal Ambx::Protocol::SET_TIMED_COLOR_SEQUENCE
  end
end
