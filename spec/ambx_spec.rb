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
  WWLEFT = 0x09
  WWCENTER = 0x0A
  WWRIGHT = 0x0C
  RIGHT = 0x0D
end

module LIBUSB
  class ERROR_NOT_FOUND < StandardError; end

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
    attr_reader :claim_calls, :close_calls, :transfer_calls
    attr_accessor :auto_detach_kernel_driver

    def initialize(claim_result: true)
      @claim_result = claim_result
      @claim_calls = 0
      @close_calls = 0
      @transfer_calls = 0
    end

    def claim_interface(_number)
      @claim_calls += 1
      @claim_result
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
    attr_reader :bus_number, :device_address, :port_path

    def initialize(vendor_id: ProtocolDefinitions::USB_VENDOR_ID, product_id: ProtocolDefinitions::USB_PRODUCT_ID,
      serial_number: nil, serial_error: nil, port_path: nil, port_numbers: nil, bus_number: 1, device_address: 2, handle: FakeHandle)
      @vendor_id = vendor_id
      @product_id = product_id
      @serial_number = serial_number
      @serial_error = serial_error
      @port_path = port_path
      @port_numbers = port_numbers
      @bus_number = bus_number
      @device_address = device_address
      @handle = handle
    end

    def idVendor
      @vendor_id
    end

    def idProduct
      @product_id
    end

    def serial_number
      raise @serial_error if @serial_error

      @serial_number
    end

    def port_numbers
      @port_numbers
    end

    def open
      handle = @handle.new
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

  class FakeDeviceWithUnclaimableHandle < FakeDevice
    def open
      handle = FakeHandle.new(claim_result: nil)
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

  def test_devices_discovers_only_matching_usb_descriptors_without_opening_them
    matching = AmbxDeviceTestState::FakeDevice.new(serial_number: "living-room")
    another_matching = AmbxDeviceTestState::FakeDevice.new(serial_number: "office")
    non_matching = AmbxDeviceTestState::FakeDevice.new(vendor_id: 0x1234)
    AmbxDeviceTestState.devices = [ matching, another_matching, non_matching ]

    devices = Ambx.devices

    assert_equal 2, devices.length
    assert_instance_of Ambx::Device, devices.fetch(0)
    assert_equal "living-room", devices.fetch(0).serial_number
    assert_equal "office", devices.fetch(1).serial_number
    refute_same devices.fetch(0), Ambx.devices.fetch(0)
    assert_empty AmbxDeviceTestState.opened_handles
  end

  def test_device_identity_prefers_serial_then_port_path_then_bus_and_address
    AmbxDeviceTestState.devices = [
      AmbxDeviceTestState::FakeDevice.new(serial_number: "set-1", port_path: [ 1, 2 ], bus_number: 3, device_address: 4),
      AmbxDeviceTestState::FakeDevice.new(port_path: [ 2, 5 ], bus_number: 3, device_address: 5),
      AmbxDeviceTestState::FakeDevice.new(bus_number: 4, device_address: 6)
    ]

    serial_device, port_device, usb_device = Ambx.devices

    assert_equal "serial:set-1", serial_device.identity
    assert_equal "set-1", serial_device.serial_number
    assert_equal [ 1, 2 ], serial_device.port_path
    assert_equal "port:2.5", port_device.identity
    assert_equal [ 2, 5 ], port_device.port_path
    assert_equal "usb:4-6", usb_device.identity
  end

  def test_device_uses_port_numbers_and_tolerates_an_unavailable_serial_number
    AmbxDeviceTestState.devices = [
      AmbxDeviceTestState::FakeDevice.new(serial_error: LIBUSB::ERROR_NOT_FOUND.new, port_numbers: [ 3, 7 ]),
      AmbxDeviceTestState::FakeDevice.new(port_path: "4/8")
    ]

    port_numbers_device, string_port_device = Ambx.devices

    assert_nil port_numbers_device.serial_number
    assert_equal [ 3, 7 ], port_numbers_device.port_path
    assert_equal "port:3.7", port_numbers_device.identity
    assert_equal "4/8", string_port_device.port_path
    assert_equal "port:4.8", string_port_device.identity
  end

  def test_device_opens_and_closes_only_its_own_handle
    descriptor = AmbxDeviceTestState::FakeDevice.new
    AmbxDeviceTestState.devices = [ descriptor, AmbxDeviceTestState::FakeDevice.new ]
    device = Ambx.devices.fetch(0)

    refute device.connected?
    assert_same device, device.open
    assert_same device, device.open

    handle = AmbxDeviceTestState.opened_handles.fetch(0)
    assert_equal 1, AmbxDeviceTestState.opened_handles.length
    assert_equal 1, handle.claim_calls
    assert device.connected?

    device.close
    device.close

    refute device.connected?
    assert_equal 0, handle.transfer_calls
    assert_equal 1, handle.close_calls
  end

  def test_closing_one_device_does_not_disconnect_or_write_to_another_device
    AmbxDeviceTestState.devices = [ AmbxDeviceTestState::FakeDevice.new, AmbxDeviceTestState::FakeDevice.new ]
    first_device, second_device = Ambx.devices
    first_device.open
    second_device.open

    first_handle, second_handle = AmbxDeviceTestState.opened_handles
    first_device.close

    refute first_device.connected?
    assert second_device.connected?
    assert_equal 1, first_handle.close_calls
    assert_equal 0, first_handle.transfer_calls
    assert_equal 0, second_handle.close_calls
    assert_equal 0, second_handle.transfer_calls

    second_device.write([ 0x01, Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00 ])

    assert_equal 1, second_handle.transfer_calls
  end

  def test_device_clear_lights_writes_five_commands_to_its_own_handle
    AmbxDeviceTestState.devices = [ AmbxDeviceTestState::FakeDevice.new, AmbxDeviceTestState::FakeDevice.new ]
    device = Ambx.devices.fetch(0).open
    handle = AmbxDeviceTestState.opened_handles.fetch(0)

    device.close(clear_lights: true)

    assert_equal 5, handle.transfer_calls
    assert_equal 1, handle.close_calls
    assert_equal 1, AmbxDeviceTestState.opened_handles.length
  end

  def test_device_releases_its_handle_when_interface_cannot_be_claimed
    AmbxDeviceTestState.devices = [ AmbxDeviceTestState::FakeDeviceWithUnclaimableHandle.new ]
    device = Ambx.devices.fetch(0)

    assert_equal false, device.open

    handle = AmbxDeviceTestState.opened_handles.fetch(0)
    assert_equal 4, handle.claim_calls
    assert_equal 1, handle.close_calls
    refute device.connected?
  end
end
