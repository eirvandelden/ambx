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

  # Light IDs eligible for brightness tracking and replay.
  # Fans, rumble, and any future non-light outputs are excluded.
  LIGHT_IDS = [ Lights::LEFT, Lights::RIGHT, Lights::WWLEFT, Lights::WWCENTER, Lights::WWRIGHT ].freeze

  @device      = nil # device in the usb tree
  @handle      = nil # device opened
  @devices     = []
  @handles     = nil
  # Preserved across reconnects so reapply_brightness can restore state after a USB re-open.
  @light_state = {}

  class << self
    attr_reader :handles
  end

  # Find the device by finding it in the device tree, fail if it's not connected
  def self.connect
    @devices = []

    LIBUSB::Context.new.devices.select do |dev|
      dev.idVendor == ProtocolDefinitions::USB_VENDOR_ID && dev.idProduct == ProtocolDefinitions::USB_PRODUCT_ID
    end.each do |dev|
      if !@device.nil?
        @device = dev
        # break
      end

      @devices << dev

      true
    end

    !@devices.empty?
  end

  # Open the device if it has been connected before.
  # If the device hasn't been opened yet, try to open it otherwise fail
  def self.open
    return true if Ambx.connected?
    return false if (@devices.nil? || @devices.all? { |dev| dev.nil? }) && !Ambx.connect

    handles = @devices.map { |device| device.open }
    if handles.any?(&:nil?)
      handles.compact.each { |handle| Ambx.close_device(handle) }
      return false
    end

    # we retry a few times to open the device or kill it
    claimed = handles.all? { |handle| Ambx.claim_interface(handle) }
    unless claimed
      handles.each { |handle| Ambx.close_device(handle) }
      return false
    end

    @handles = handles
    true
  end

  # Try to claim interface
  def self.claim_interface(handle)
    retries = 0
    max_retries = 3
    begin
      error_code = handle.claim_interface(0)
    rescue ArgumentError
    end

    raise CannotClaimInterfaceError if error_code.nil? # TODO: libusb doesn't return anything on error
    return true
  rescue CannotClaimInterfaceError
    if retries < max_retries
      handle.auto_detach_kernel_driver = true
      retries                         += 1
      retry
    else
      false
    end
  else
    false
  end

  # Check if device handles are currently open and valid
  # @return [Boolean] true if connected with valid handles, false otherwise
  def self.connected?
    !@handles.nil? && !@handles.all? { |handle| handle.nil? }
  end

  # Close the device if it is open.
  # set clearLights to true to try and set the lights back to 0x00
  def self.close (clearLights = false)
    return if @handles.nil? || @handles.all? { |handle| handle.nil? }

    @handles.each { |handle| Ambx.close_device(handle, clearLights) }

    @device  = nil
    @handles = nil
    @devices = []
    # @light_state is intentionally preserved so reapply_brightness works after reconnect.
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

  # Writes a set of bytes to the USB device.
  # Sends the provided bytes to all currently opened device handles.
  # If no handles are available, the call performs no action.
  # Tracks unscaled source RGB for light commands so brightness can be reapplied correctly.
  #
  # @param [Array<Integer>] bytes Sequence of bytes (0-255) to send to the device.
  # @return [void]
  # @example Set WW center light to green
  #   Ambx.write([0x01, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00])
  def self.write(bytes)
    return if @handles.nil? || @handles.all? { |handle| handle.nil? } # we lost it. see issue #1 on google code.

    record_source_light(bytes) if source_light_command?(bytes)
    write_to_handles(bytes)
  end

  # Re-send all tracked lights at the current brightness level.
  # Called by BrightnessController.adjust after updating the multiplier.
  # Uses write_to_handles directly to avoid re-tracking the scaled replay bytes.
  def self.reapply_brightness
    @light_state.each do |light_id, (r, g, b)|
      write_to_handles([ 0xA1, light_id, ProtocolDefinitions::SET_LIGHT_COLOR,
                        *BrightnessController.apply(r, g, b) ])
    end
  end

  class << self
    private

    def write_to_handles(bytes)
      return if @handles.nil?

      @handles.each { |handle| write_device(handle, bytes) if handle }
    end

    # Returns true only for light-color writes targeting a tracked light ID.
    # Fans, rumble, and other non-light commands are excluded.
    def source_light_command?(bytes)
      bytes[0] == 0xA1 &&
        bytes[2] == ProtocolDefinitions::SET_LIGHT_COLOR &&
        LIGHT_IDS.include?(bytes[1])
    end

    # Stores the unscaled RGB for a light so reapply_brightness has the source values.
    def record_source_light(bytes)
      @light_state[bytes[1]] = [ bytes[3], bytes[4], bytes[5] ]
    end

    # Write a set of bytes to the usb device, this is our command string. Try to open it if necessarily.
    def write_device(handle, bytes)
      handle.interrupt_transfer(
        endpoint: ProtocolDefinitions::ENDPOINT_OUT,
        dataOut: bytes.pack("C*"),
        timeout: 0
      )
      # quick fix to not immediately segfault, but wait for segfault when application quits.
      # need a fix somewhere in ruby_usb, see issue #1 on google code.
    rescue Errno::ENXIO
      Ambx.close
    end
  end
end
