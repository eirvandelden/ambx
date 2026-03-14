require_relative "../../test_helper"

ALL_FAN_IDS = [ Ambx::Fans::LEFT, Ambx::Fans::RIGHT ].freeze

describe Ambx::Fans, "fan addresses" do
  it "LEFT is 0x5B" do
    _(Ambx::Fans::LEFT).must_equal 0x5B
  end

  it "RIGHT is 0x6B" do
    _(Ambx::Fans::RIGHT).must_equal 0x6B
  end

  it "LEFT and RIGHT are distinct" do
    _(Ambx::Fans::LEFT).wont_equal Ambx::Fans::RIGHT
  end
end

describe Ambx::Fans, "hardware address convention: lower nibble" do
  it "all fan addresses end in 0xB (lower nibble = 0xB)" do
    ALL_FAN_IDS.each do |id|
      _(id & 0x0F).must_equal 0x0B, "expected 0x#{id.to_s(16)} to end in 0xB"
    end
  end
end
