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

  # After the brightness level changes, newly written light colors must also be
  # scaled. Before the fix, only reapply_brightness used the multiplier, so the
  # next Ambx.write sent the raw unscaled RGB and effectively reset brightness.
  def test_new_light_writes_respect_current_brightness_level
    BrightnessController.adjust(-10) # 1.0 → 0.5
    Ambx.write(FULL_RED)

    assert_equal [ 0xA1, Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 100, 50, 25 ], @handle.transfers.last,
      "New writes must be scaled to the current brightness level"
  end

  def test_legacy_five_byte_light_writes_respect_current_brightness_level
    BrightnessController.adjust(-10) # 1.0 → 0.5
    Ambx.write([ Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 100, 0, 0 ])

    assert_equal [ Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 50, 0, 0 ], @handle.transfers.last,
      "Legacy five-byte light writes must be scaled to the current brightness level"
  end

  def test_legacy_five_byte_light_writes_are_replayed_after_brightness_change
    Ambx.write([ Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 100, 0, 0 ])
    @handle.transfers.clear

    BrightnessController.adjust(-10) # 1.0 → 0.5

    assert_equal [ 0xA1, Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 50, 0, 0 ], @handle.transfers.last,
      "Legacy five-byte light writes must be replayed after a brightness change"
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

  # BrightnessController.adjust must be a safe no-op when the device is disconnected.
  # Before the fix, reapply_brightness called write_to_handles which called @handles.each
  # on a nil value, raising NoMethodError and crashing the process.
  def test_brightness_adjust_is_safe_noop_when_disconnected
    Ambx.write(FULL_RED)
    Ambx.instance_variable_set(:@handles, nil)

    assert_silent { BrightnessController.adjust(-1) }
  end

  # If the device disconnects mid-replay (Errno::ENXIO nils out @handles inside write_device),
  # the remaining iterations of reapply_brightness must not raise NoMethodError.
  def test_mid_replay_disconnect_does_not_raise
    disconnecting_handle = Object.new
    def disconnecting_handle.close = nil
    def disconnecting_handle.interrupt_transfer(**) = raise(Errno::ENXIO)

    Ambx.instance_variable_set(:@handles, [ disconnecting_handle ])
    Ambx.instance_variable_set(:@light_state, {
      Lights::LEFT  => [ 200, 100, 50 ],
      Lights::RIGHT => [ 50, 100, 200 ]
    })

    assert_silent { Ambx.reapply_brightness }
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
