require_relative "../../test_helper"

ALL_LIGHT_IDS = [
  Ambx::Lights::LEFT, Ambx::Lights::RIGHT,
  Ambx::Lights::WWLEFT, Ambx::Lights::WWCENTER, Ambx::Lights::WWRIGHT
].freeze

describe Ambx::Lights, "side lights" do
  it "LEFT is 0x0B" do
    _(Ambx::Lights::LEFT).must_equal 0x0B
  end

  it "RIGHT is 0x1B" do
    _(Ambx::Lights::RIGHT).must_equal 0x1B
  end

  it "LEFT and RIGHT are distinct" do
    _(Ambx::Lights::LEFT).wont_equal Ambx::Lights::RIGHT
  end
end

describe Ambx::Lights, "wallwasher lights" do
  it "WWLEFT is 0x2B" do
    _(Ambx::Lights::WWLEFT).must_equal 0x2B
  end

  it "WWCENTER is 0x3B" do
    _(Ambx::Lights::WWCENTER).must_equal 0x3B
  end

  it "WWRIGHT is 0x4B" do
    _(Ambx::Lights::WWRIGHT).must_equal 0x4B
  end

  it "all three wallwasher IDs are distinct" do
    ids = [ Ambx::Lights::WWLEFT, Ambx::Lights::WWCENTER, Ambx::Lights::WWRIGHT ]
    _(ids.uniq.length).must_equal 3
  end
end

describe Ambx::Lights, "hardware address convention: lower nibble" do
  it "all addresses end in 0xB (lower nibble = 0xB)" do
    ALL_LIGHT_IDS.each do |id|
      _(id & 0x0F).must_equal 0x0B, "expected 0x#{id.to_s(16)} to end in 0xB"
    end
  end
end

describe Ambx::Lights, "hardware address convention: uniqueness" do
  it "all addresses are unique" do
    _(ALL_LIGHT_IDS.uniq.length).must_equal ALL_LIGHT_IDS.length
  end
end

describe Ambx::Lights, "hardware address convention: ordering" do
  it "addresses increase monotonically (LEFT -> WWRIGHT)" do
    _(ALL_LIGHT_IDS).must_equal ALL_LIGHT_IDS.sort
  end
end
