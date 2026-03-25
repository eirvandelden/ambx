require "minitest/autorun"

require_relative "../libcombustd/data/lights"
require_relative "../libcombustd/data/protocoldefinitions"
require_relative "../libcombustd/communication/ambx"
require_relative "../libcombustd/lighting/brightness_controller"

# Minimal USB handle stand-in that records every interrupt transfer.
class FakeHandle
  attr_reader :transfers

  def initialize = @transfers = []

  def interrupt_transfer(endpoint:, dataOut:, timeout:)
    @transfers << dataOut.unpack("C*")
  end
end

class AmbxBrightnessTest < Minitest::Test
  FULL_RED = [ 0xA1, Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 200, 100, 50 ].freeze
  FAN_CMD  = [ 0xA1, Lights::LEFT_FAN, ProtocolDefinitions::SET_LIGHT_COLOR, 0, 0, 200 ].freeze

  def setup
    @handle = FakeHandle.new
    Ambx.instance_variable_set(:@handles, [ @handle ])
    Ambx.instance_variable_set(:@light_state, {})
    BrightnessController.instance_variable_set(:@level, 1.0)
  end

  def teardown
    Ambx.instance_variable_set(:@handles, nil)
    Ambx.instance_variable_set(:@light_state, {})
    BrightnessController.instance_variable_set(:@level, 1.0)
  end

  # Dimming and then brightening back must reproduce the original unscaled color.
  # Before the fix, reapply_brightness overwrote @light_state with scaled values,
  # so a second adjustment would scale already-scaled data.
  def test_original_color_is_preserved_across_brightness_round_trip
    Ambx.write(FULL_RED)

    BrightnessController.adjust(-10) # 1.0 → 0.5
    BrightnessController.adjust(10)  # 0.5 → 1.0

    assert_equal FULL_RED, @handle.transfers.last,
      "After round-trip brightness adjustment the replayed color must match the original"
  end

  # Fan writes share the SET_LIGHT_COLOR command byte but must never enter the
  # brightness replay set.  Before the fix, fans were tracked and replayed with
  # their speed bytes passed through BrightnessController.apply.
  def test_fan_writes_are_not_replayed_by_brightness_changes
    Ambx.write(FAN_CMD)
    @handle.transfers.clear

    Ambx.reapply_brightness

    assert_empty @handle.transfers,
      "Fan commands must not be replayed when brightness changes"
  end

  class WhenMultipleLightsAreTracked < Minitest::Test
    def setup
      @handle = FakeHandle.new
      Ambx.instance_variable_set(:@handles, [ @handle ])
      Ambx.instance_variable_set(:@light_state, {})
      BrightnessController.instance_variable_set(:@level, 1.0)
    end

    def teardown
      Ambx.instance_variable_set(:@handles, nil)
      Ambx.instance_variable_set(:@light_state, {})
      BrightnessController.instance_variable_set(:@level, 1.0)
    end

    def test_all_tracked_lights_are_replayed_at_new_brightness
      Ambx.write([ 0xA1, Lights::LEFT,  ProtocolDefinitions::SET_LIGHT_COLOR, 100, 0, 0 ])
      Ambx.write([ 0xA1, Lights::RIGHT, ProtocolDefinitions::SET_LIGHT_COLOR, 0, 100, 0 ])
      @handle.transfers.clear

      BrightnessController.adjust(-10) # 1.0 → 0.5

      assert_equal 2, @handle.transfers.size, "Both lights must be replayed"
    end
  end
end
