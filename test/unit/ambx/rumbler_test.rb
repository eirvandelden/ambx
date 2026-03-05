require_relative "../../test_helper"

describe Ambx::Rumbler, "keyboard accessory address" do
  it "KEYBOARD is 0x7B" do
    _(Ambx::Rumbler::KEYBOARD).must_equal 0x7B
  end

  it "address ends in 0xB (lower nibble = 0xB)" do
    _(Ambx::Rumbler::KEYBOARD & 0x0F).must_equal 0x0B
  end
end
