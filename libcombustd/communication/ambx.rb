require "singleton"

# Ambx manages all traffic flowing to the amBX device.
# Handles all connections and errors, which can be boolean-checked by the application.
# @example Basic usage
#   Ambx.open
#   Ambx.connect
#   Ambx.write_all([0x01, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00])
#   Ambx.close
# @note This class is a Singleton; use class methods or Ambx.instance.
class Ambx
  include Singleton

  CLAIM_INTERFACE_RETRIES = 3

  @legacy_devices = []

  # Find the device by finding it in the device tree, fail if it's not connected
  def self.devices
    usb_connection.devices.filter_map do |dev|
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
  rescue StandardError
    Ambx.close
    raise
  end

  # Try to claim interface
  def self.claim_interface(handle, retry_busy: false)
    attempts = 0

    loop do
      return true if claim_interface_result(handle, retry_busy:)
      return false unless retry_claim_interface?(handle, attempts += 1)
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
    legacy_devices = @legacy_devices
    @legacy_devices = []
    legacy_devices.each { |device| device.close(clear_lights: clearLights) }
  end

  # Writes bytes to every device opened through the legacy broadcast facade.
  # Stops at the first disconnected device and closes all legacy devices.
  #
  # @param [Array<Integer>] bytes Sequence of bytes (0-255) to send to the device.
  # @return [Boolean] true when every device accepted the transfer
  # @example Set WW center light to green
  #   Ambx.write_all([0x01, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00])
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

  def self.claim_interface_result(handle, retry_busy:)
    handle.claim_interface(0)
  rescue ArgumentError
    nil
  rescue LIBUSB::ERROR_BUSY
    raise unless retry_busy

    nil
  end

  def self.retry_claim_interface?(handle, attempts)
    return false if attempts > CLAIM_INTERFACE_RETRIES

    handle.auto_detach_kernel_driver = true
    true
  end

  # The connection to the USB subsystem outlives every scan, so the devices handed
  # out by a scan stay usable for as long as the caller keeps them.
  def self.usb_connection
    @usb_connection ||= LIBUSB::Context.new
  end

  private_class_method :claim_interface_result, :retry_claim_interface?, :usb_connection
end

require_relative "device"
