require "minitest/autorun"

class CannotClaimInterfaceError < StandardError; end

module ProtocolDefinitions
  USB_VENDOR_ID = 0x0471
  USB_PRODUCT_ID = 0x083F
  ENDPOINT_OUT = 0x02
  SET_LIGHT_COLOR = 0x03
end

class Lights
  LEFT = 0x0B
end

module LIBUSB
  class Context
    def devices
      AmbxDeviceTestState.devices
    end
  end
end

module AmbxDeviceTestState
  class << self
    attr_accessor :devices, :opened_handles

    def reset!
      @opened_handles = []
      @devices = [ FakeDevice.new ]
    end
  end

  class FakeHandle
    attr_reader :close_calls, :transfer_calls
    attr_accessor :auto_detach_kernel_driver

    def initialize
      @close_calls = 0
      @transfer_calls = 0
    end

    def claim_interface(_number)
      true
    end

    def close
      @close_calls += 1
    end

    def interrupt_transfer(endpoint:, dataOut:, timeout:)
      @transfer_calls += 1
      [ endpoint, dataOut, timeout ]
    end
  end

  class FakeHandleRaisingENXIO < FakeHandle
    def interrupt_transfer(endpoint:, dataOut:, timeout:)
      @transfer_calls += 1
      raise Errno::ENXIO
    end
  end

  class FakeDevice
    def idVendor
      ProtocolDefinitions::USB_VENDOR_ID
    end

    def idProduct
      ProtocolDefinitions::USB_PRODUCT_ID
    end

    def open
      handle = FakeHandle.new
      AmbxDeviceTestState.opened_handles << handle
      handle
    end
  end

  class FakeDeviceWithENXIOHandle < FakeDevice
    def open
      handle = FakeHandleRaisingENXIO.new
      AmbxDeviceTestState.opened_handles << handle
      handle
    end
  end
end

require_relative "../libcombustd/communication/ambx"

class AmbxTest < Minitest::Test
  def setup
    AmbxDeviceTestState.reset!
    Ambx.close
  end

  def teardown
    Ambx.close
  end

  def test_open_is_idempotent_while_connected
    assert Ambx.connect
    assert Ambx.open
    assert Ambx.open

    assert_equal 1, AmbxDeviceTestState.opened_handles.length
  end

  def test_close_releases_open_handle_after_repeated_open_calls
    assert Ambx.connect
    assert Ambx.open
    assert Ambx.open

    handle = AmbxDeviceTestState.opened_handles.fetch(0)
    Ambx.close

    assert_equal 1, handle.close_calls
  end

  def test_write_does_not_crash_when_first_of_two_handles_raises_enxio
    AmbxDeviceTestState.devices = [
      AmbxDeviceTestState::FakeDeviceWithENXIOHandle.new,
      AmbxDeviceTestState::FakeDevice.new
    ]
    assert Ambx.connect
    assert Ambx.open

    enxio_handle = AmbxDeviceTestState.opened_handles.fetch(0)
    second_handle = AmbxDeviceTestState.opened_handles.fetch(1)

    assert_silent { Ambx.write([ 0x01, Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00 ]) }

    assert_equal 1, enxio_handle.transfer_calls, "first handle should have been attempted"
    assert_equal 0, second_handle.transfer_calls, "second handle must not be called after close"
  end
end
