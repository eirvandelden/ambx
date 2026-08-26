require "singleton"

# Ambx manages all traffic flowing to the amBX device.
# Handles all connections and errors, which can be boolean-checked by the application.
# @example Basic usage
#   Ambx.open
#   Ambx.connect
#   Ambx.write([0x01, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00])
#   Ambx.close
# @note This class is a Singleton; use class methods or Ambx.instance.
class Ambx
  include Singleton

  @legacy_devices = []

  # Find the device by finding it in the device tree, fail if it's not connected
  def self.devices
    LIBUSB::Context.new.devices.filter_map do |dev|
      Device.new(dev) if dev.idVendor == ProtocolDefinitions::USB_VENDOR_ID && dev.idProduct == ProtocolDefinitions::USB_PRODUCT_ID
    end
  end

  # Find the device by finding it in the device tree, fail if it's not connected
  def self.connect
    @legacy_devices = devices
    !@legacy_devices.empty?
  end

  # Open the device if it has been connected before.
  # If the device hasn't been opened yet, try to open it otherwise fail
  def self.open
    return true if Ambx.connected?
    return false if @legacy_devices.empty? && !Ambx.connect

    opened_devices = @legacy_devices.map(&:open)
    if opened_devices.any?(false)
      Ambx.close
      return false
    end

    true
  end

  # Try to claim interface
  def self.claim_interface(handle)
    retries = 0
    max_retries = 3
    begin
      begin
        error_code = handle.claim_interface(0)
      rescue ArgumentError
      end

      raise CannotClaimInterfaceError if error_code.nil? # TODO: libusb doesn't return anything on error
      true
    rescue CannotClaimInterfaceError
      if retries < max_retries
        handle.auto_detach_kernel_driver = true
        retries                         += 1
        retry
      else
        false
      end
    end
  end

  # Check if device handles are currently open and valid
  # @return [Boolean] true if connected with valid handles, false otherwise
  def self.connected?
    @legacy_devices.any?(&:connected?)
  end

  # Close the device if it is open.
  # set clearLights to true to try and set the lights back to 0x00
  def self.close (clearLights = false)
    @legacy_devices.each { |device| device.close(clear_lights: clearLights) }
    @legacy_devices = []
  end

  def self.close_device(handle, clearLights = false)
    if clearLights
      Ambx.write([ 0xA1, Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Lights::WWLEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Lights::WWRIGHT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Lights::RIGHT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
    end

    begin
      handle.close
    rescue Errno::ENXIO
    end
  end

  # Writes bytes to every device opened through the legacy broadcast facade.
  # Stops at the first disconnected device and closes all legacy devices.
  #
  # @param [Array<Integer>] bytes Sequence of bytes (0-255) to send to the device.
  # @return [Boolean] true when every device accepted the transfer
  # @example Set WW center light to green
  #   Ambx.write([0x01, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00])
  def self.write_all(bytes)
    return false if @legacy_devices.empty?

    @legacy_devices.each do |device|
      next if device.write(bytes)

      Ambx.close
      return false
    end

    true
  end

  def self.write(bytes)
    unless @write_deprecation_warned
      warn "Ambx.write is deprecated; use Ambx.write_all instead."
      @write_deprecation_warned = true
    end

    write_all(bytes)
  end

  # Write a set of bytes to the usb device, this is our command string. Try to open it if necessarily.
  # Returns false if the device was lost (ENXIO), true otherwise.
  def self.write_device(handle, bytes)
    handle.interrupt_transfer(
      endpoint: ProtocolDefinitions::ENDPOINT_OUT,
      dataOut: bytes.pack("C*"),
      timeout: 0
    )
    # quick fix to not immediately segfault, but wait for segfault when application quits.
    # need a fix somewhere in ruby_usb, see issue #1 on google code.
    true
  rescue Errno::ENXIO
    Ambx.close
    false
  end
end

require_relative "device"
