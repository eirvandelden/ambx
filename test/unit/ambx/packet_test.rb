require_relative "../../test_helper"

ALL_LIGHTS = [
  Ambx::Lights::LEFT, Ambx::Lights::RIGHT,
  Ambx::Lights::WWLEFT, Ambx::Lights::WWCENTER, Ambx::Lights::WWRIGHT
].freeze

describe Ambx::Packet, ".set_color packet layout" do
  let(:packet) { Ambx::Packet.set_color(Ambx::Lights::LEFT, 100, 150, 200) }

  it "returns a Packet" do
    _(packet).must_be_instance_of Ambx::Packet
  end

  it "produces a 6-byte packet" do
    _(packet.to_a.length).must_equal 6
  end

  it "starts with preamble and command bytes" do
    _(packet.to_a[0]).must_equal 0xA1
    _(packet.to_a[2]).must_equal Ambx::Protocol::SET_LIGHT_COLOR
  end

  it "places R, G, B in bytes 4-6" do
    _(packet.to_a[3..5]).must_equal [ 100, 150, 200 ]
  end
end

describe Ambx::Packet, ".set_color clamping" do
  it "clamps values above 255 to 255" do
    packet = Ambx::Packet.set_color(Ambx::Lights::LEFT, 300, 999, 256)
    _(packet.to_a[3..5]).must_equal [ 255, 255, 255 ]
  end

  it "clamps negative values to 0" do
    packet = Ambx::Packet.set_color(Ambx::Lights::LEFT, -1, -100, -255)
    _(packet.to_a[3..5]).must_equal [ 0, 0, 0 ]
  end

  it "keeps boundary values unchanged" do
    packet = Ambx::Packet.set_color(Ambx::Lights::LEFT, 0, 128, 255)
    _(packet.to_a[3..5]).must_equal [ 0, 128, 255 ]
  end
end

describe Ambx::Packet, ".set_color float rounding" do
  it "rounds floats before clamping" do
    packet = Ambx::Packet.set_color(Ambx::Lights::LEFT, 127.6, 0.4, 254.5)
    _(packet.to_a[3..5]).must_equal [ 128, 0, 255 ]
  end

  it "handles boblight-style float*255 inputs" do
    packet = Ambx::Packet.set_color(Ambx::Lights::LEFT, 1.0 * 255, 0.5 * 255, 0.0 * 255)
    _(packet.to_a[3..5]).must_equal [ 255, 128, 0 ]
  end
end

describe Ambx::Packet, ".set_color addresses" do
  it "works with every defined light address" do
    ALL_LIGHTS.each do |light_id|
      packet = Ambx::Packet.set_color(light_id, 255, 255, 255)
      _(packet.to_a[1]).must_equal light_id
    end
  end
end

describe Ambx::Packet, ".set_fan packet layout" do
  let(:packet) { Ambx::Packet.set_fan(Ambx::Fans::LEFT, 128) }

  it "returns a Packet" do
    _(packet).must_be_instance_of Ambx::Packet
  end

  it "uses preamble, fan address and color opcode" do
    _(packet.to_a[0]).must_equal 0xA1
    _(packet.to_a[1]).must_equal Ambx::Fans::LEFT
    _(packet.to_a[2]).must_equal Ambx::Protocol::SET_LIGHT_COLOR
  end

  it "encodes speed in the blue channel only" do
    _(packet.to_a[3..5]).must_equal [ 0, 0, 128 ]
  end
end

describe Ambx::Packet, ".set_fan clamping" do
  it "clamps speed above 255 to 255" do
    packet = Ambx::Packet.set_fan(Ambx::Fans::LEFT, 300)
    _(packet.to_a[5]).must_equal 255
  end

  it "clamps negative speed to 0" do
    packet = Ambx::Packet.set_fan(Ambx::Fans::LEFT, -50)
    _(packet.to_a[5]).must_equal 0
  end

  it "keeps boundary values unchanged" do
    _(Ambx::Packet.set_fan(Ambx::Fans::LEFT, 0).to_a[5]).must_equal 0
    _(Ambx::Packet.set_fan(Ambx::Fans::LEFT, 255).to_a[5]).must_equal 255
  end
end

describe Ambx::Packet, ".set_fan float rounding" do
  it "rounds float speed values" do
    packet = Ambx::Packet.set_fan(Ambx::Fans::LEFT, 63.7)
    _(packet.to_a[5]).must_equal 64
  end

  it "rounds 0.4 down to 0" do
    packet = Ambx::Packet.set_fan(Ambx::Fans::LEFT, 0.4)
    _(packet.to_a[5]).must_equal 0
  end
end

describe Ambx::Packet, "#to_a" do
  it "returns a copy and not the internal array" do
    packet = Ambx::Packet.set_color(Ambx::Lights::LEFT, 0, 0, 0)
    array = packet.to_a
    array[0] = 0xFF
    _(packet.to_a[0]).must_equal 0xA1
  end
end

describe Ambx::Packet, "#bytes" do
  it "exposes the frozen raw byte array" do
    packet = Ambx::Packet.set_color(Ambx::Lights::LEFT, 10, 20, 30)
    _(packet.bytes).must_equal [ 0xA1, Ambx::Lights::LEFT, 0x03, 10, 20, 30 ]
    _(packet.bytes).must_be :frozen?
  end
end
