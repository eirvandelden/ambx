require "minitest/autorun"

# ---------------------------------------------------------------------------
# Stubs — must be defined BEFORE requiring menubar_helpers so the constant
# references resolve at call time, not at require time.
# ---------------------------------------------------------------------------

class Lights
  LEFT      = 0x0B
  WWLEFT    = 0x2B
  WWCENTER  = 0x3B
  WWRIGHT   = 0x4B
  RIGHT     = 0x1B
  LEFT_FAN  = 0x5B
  RIGHT_FAN = 0x6B
end

COLORS      = [ { "name" => "Warm White", "rgb" => [ 255, 244, 229 ] } ]
FAN_SPEEDS  = [ { "name" => "Fan: Low", "speed" => 64 } ]
GREEN_BOOST = 1.0

# Controllable Ambx stub
module AmbxStub
  @connect    = true
  @open       = true
  @connected  = true
  @write_log  = []

  class << self
    attr_accessor :connect, :open, :connected
    attr_reader :write_log

    def reset!
      @connect   = true
      @open      = true
      @connected = true
      @write_log = []
      # Restore any singleton methods that tests may have overridden via define_singleton_method
      AmbxStub.define_singleton_method(:write)   { |bytes| @write_log << bytes }
      AmbxStub.define_singleton_method(:connect) { @connect }
      AmbxStub.define_singleton_method(:open)    { @open }
    end

    def connect  = @connect
    def open     = @open
    def connected? = @connected
    def write(bytes) = @write_log << bytes
    def close    = nil
  end
end

# Point the global Ambx constant at our stub
Ambx = AmbxStub

require_relative "../../applications/menubar/menubar_helpers"

# ---------------------------------------------------------------------------
class MenubarHelpersTest < Minitest::Test
  def setup
    AmbxStub.reset!
  end

  def test_init_ambx_returns_true_when_connect_and_open_succeed
    AmbxStub.connect = true
    AmbxStub.open    = true
    assert init_ambx
  end

  def test_init_ambx_returns_false_when_connect_fails
    AmbxStub.connect = false
    refute init_ambx
  end

  def test_init_ambx_returns_false_when_open_fails
    AmbxStub.connect = true
    AmbxStub.open    = false
    refute init_ambx
  end

  def test_print_menu_shows_disconnected_when_open_fails
    AmbxStub.connect = true
    AmbxStub.open    = false
    connected = init_ambx
    out = capture_io { print_menu(connected) }.first
    assert_includes out, STRINGS[:disconnected]
    refute_includes out, STRINGS[:connected]
  end

  def test_set_all_lights_returns_true_when_connected_throughout
    AmbxStub.connected = true
    assert set_all_lights(255, 0, 0)
  end

  def test_set_all_lights_returns_false_when_reconnect_fails
    # Device disconnects on first write, reconnect also fails
    write_count = 0
    AmbxStub.define_singleton_method(:write) do |bytes|
      @write_log << bytes
      @connected = false  # disconnect after every write
    end
    AmbxStub.connect = false  # reconnect will also fail

    refute set_all_lights(255, 0, 0)
  end

  def test_set_all_lights_does_not_recurse_more_than_once
    # Device disconnects after first write; reconnect succeeds but then
    # disconnects again immediately. Must stop after MAX_RECONNECT_ATTEMPTS.
    write_count = 0
    AmbxStub.define_singleton_method(:write) do |bytes|
      @write_log << bytes
      @connected = false  # always disconnect after a write
    end
    AmbxStub.define_singleton_method(:connect) { true }
    AmbxStub.define_singleton_method(:open)    { true }

    # Should return false (gave up) rather than recurse indefinitely
    result = set_all_lights(255, 0, 0)
    refute result
    # Total writes bounded: at most (5 lights * (MAX_RECONNECT_ATTEMPTS + 1)) + 1
    assert AmbxStub.write_log.length <= (5 * (MAX_RECONNECT_ATTEMPTS + 1) + 1)
  end

  def test_set_fan_speed_returns_true_when_connected_throughout
    AmbxStub.connected = true
    assert set_fan_speed(128)
  end

  def test_set_fan_speed_returns_false_when_reconnect_fails
    AmbxStub.define_singleton_method(:write) { |b| @write_log << b; @connected = false }
    AmbxStub.connect = false

    refute set_fan_speed(128)
  end

  def test_set_fan_speed_does_not_recurse_more_than_once
    AmbxStub.define_singleton_method(:write) { |b| @write_log << b; @connected = false }
    AmbxStub.define_singleton_method(:connect) { true }
    AmbxStub.define_singleton_method(:open)    { true }

    result = set_fan_speed(128)
    refute result
    assert AmbxStub.write_log.length <= (2 * (MAX_RECONNECT_ATTEMPTS + 1) + 1)
  end

  def test_print_menu_uses_strings_title
    out = capture_io { print_menu(true) }.first
    assert_includes out, STRINGS[:title]
  end

  def test_print_menu_shows_connected_string_when_connected
    out = capture_io { print_menu(true) }.first
    assert_includes out, STRINGS[:connected]
    refute_includes out, STRINGS[:disconnected]
  end

  def test_print_menu_shows_disconnected_string_when_not_connected
    out = capture_io { print_menu(false) }.first
    assert_includes out, STRINGS[:disconnected]
    refute_includes out, STRINGS[:connected]
  end

  def test_print_menu_shows_turn_off_when_connected
    out = capture_io { print_menu(true) }.first
    assert_includes out, STRINGS[:turn_off]
  end

  def test_print_menu_hides_turn_off_when_disconnected
    out = capture_io { print_menu(false) }.first
    refute_includes out, STRINGS[:turn_off]
  end

  def test_print_menu_always_shows_quit
    [ true, false ].each do |state|
      out = capture_io { print_menu(state) }.first
      assert_includes out, STRINGS[:quit]
    end
  end

  def test_no_bare_string_literals_for_menu_labels_in_menubar_rb
    source = File.read(File.expand_path("../../applications/menubar/menubar.rb", __dir__))
    refute_includes source, '"Turn Off Lights"',
      "menubar.rb must use STRINGS[:turn_off] instead of a bare string"
    refute_includes source, '"QUIT"',
      "menubar.rb must use STRINGS[:quit] instead of a bare string"
  end
end
