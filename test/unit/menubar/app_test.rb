require_relative "../../test_helper"
require_relative "../../../applications/menubar/app"

module MenubarTestLights
  LEFT = 0x0B
  WWLEFT = 0x2B
  WWCENTER = 0x3B
  WWRIGHT = 0x4B
  RIGHT = 0x1B
end

module MenubarTestFans
  LEFT = 0x5B
  RIGHT = 0x6B
end

MENUBAR_TEST_COLORS = [ { "name" => "Warm White", "rgb" => [ 255, 200, 150 ] } ].freeze
MENUBAR_TEST_FAN_SPEEDS = [ { "name" => "Fan: Medium", "speed" => 170 } ].freeze

class MenubarDeviceSpy
  attr_reader :writes, :close_count, :connect_count, :open_count

  def initialize(connect: true, open: true)
    @connect = connect
    @open = open
    @writes = []
    @close_count = 0
    @connect_count = 0
    @open_count = 0
  end

  def connect
    @connect_count += 1
    @connect
  end

  def open
    @open_count += 1
    @open
  end

  def write(bytes)
    @writes << bytes
  end

  def close
    @close_count += 1
  end
end

def build_menubar_app(device)
  Menubar::App.new(
    device: device,
    lights: MenubarTestLights,
    fans: MenubarTestFans,
    colors: MENUBAR_TEST_COLORS,
    fan_speeds: MENUBAR_TEST_FAN_SPEEDS,
    green_boost: 1.0
  )
end

describe Menubar::App, "#connection_available?" do
  it "closes the interface after probing connection status" do
    device = MenubarDeviceSpy.new
    app = build_menubar_app(device)

    _(app.connection_available?).must_equal true
    _(device.connect_count).must_equal 1
    _(device.open_count).must_equal 1
    _(device.close_count).must_equal 1
  end
end

describe Menubar::App, "#handle_selection for colors" do
  it "writes all light zones for a color selection and closes once" do
    device = MenubarDeviceSpy.new
    app = build_menubar_app(device)

    connected = app.handle_selection("Warm White", connected: false)

    _(connected).must_equal true
    _(device.writes.length).must_equal 5
    _(device.close_count).must_equal 1
  end
end

describe Menubar::App, "#handle_selection for fans" do
  it "writes both fan channels for a fan selection" do
    device = MenubarDeviceSpy.new
    app = build_menubar_app(device)

    connected = app.handle_selection("Fan: Medium", connected: false)

    _(connected).must_equal true
    _(device.writes).must_equal [
      [ 0xA1, MenubarTestFans::LEFT, 0x03, 0, 0, 170 ],
      [ 0xA1, MenubarTestFans::RIGHT, 0x03, 0, 0, 170 ]
    ]
    _(device.close_count).must_equal 1
  end
end
