require "singleton"

# Ambx class is a singleton to manage all traffic flowing to the ambx device.
# Handles all connections and errors, which can be boolean checked by the application.

# Example usage:
# Ambx.open
# Ambx.connect
# Ambx.write([0x01, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00])
# Ambx.close

class Ambx
  include Singleton

  @device  = nil # device in the usb tree
  @handle  = nil # device opened
  @devices = [ ]

  # Find the device by finding it in the device tree, fail if it's not connected
  def self.connect
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
  end

  # Open the device if it has been connected before.
  # If the device hasn't been opened yet, try to open it otherwise fail
  def self.open
    return false if @devices.all? { |dev| dev.nil? } && !Ambx.connect

    @handles = @devices.map { |device| device.open }
    # we retry a few times to open the device or kill it
    if @handles.none? { |handle| handle.nil? }
      @handles.each { |handle| Ambx.claim_interface(handle) }
    end
  end

  # Try to claim interface
  def self.claim_interface(handle)
    retries = 0
    begin
      error_code = handle.claim_interface(0)
    rescue ArgumentError
    end

    raise CannotClaimInterfaceError if error_code.nil? # TODO: libusb doesn't return anything on error
    return true
  rescue CannotClaimInterfaceError
    handle.auto_detach_kernel_driver = true
    retries                         += 1
    retry
  else
    false
  end

  # Close the device if it is open.
  # set clearLights to true to try and set the lights back to 0x00
  def self.close (clearLights = false)
    return if @handles.all? { |handle| handle.nil? }

    @handles.each { |handle| Ambx.close_device(handle, clearLights) }

    @device  = nil
    @handles = nil
    @devices = nil
  end

  def self.close_device(handle, clearLights = false)
    if clearLights
      Ambx.write([0xA1, Lights::LEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00])
      Ambx.write([0xA1, Lights::WWLEFT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00])
      Ambx.write([0xA1, Lights::WWCENTER, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00])
      Ambx.write([0xA1, Lights::WWRIGHT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00])
      Ambx.write([0xA1, Lights::RIGHT, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00])
    end

    begin
      handle.close
    rescue Errno::ENXIO
    end
  end

  # Write a set of bytes to the usb device, this is our command string. Try to open it if necessarily.
  def self.write(bytes)
    return if @handles.all? { |handle| handle.nil? } # we lost it. see issue #1 on google code.

    @handles.each do |handle|
      next if handle.nil?

      Ambx.write_device(handle, bytes)
    end
  end

  # Write a set of bytes to the usb device, this is our command string. Try to open it if necessarily.
  def self.write_device(handle, bytes)
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
