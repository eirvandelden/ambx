# Ambx manages all traffic flowing to the amBX device.
# Handles all connections and errors, which can be boolean-checked by the application.
# @example Basic usage
#   Ambx.open
#   Ambx.connect
#   Ambx.write(Ambx::Packet.set_color(Ambx::Lights::WWCENTER, 0x00, 0xFF, 0x00))
#   Ambx.close
class Ambx
  module Error
    # Raised when claiming the USB interface fails after retries.
    class CannotClaim < StandardError; end
  end

  @context = nil
  @device  = nil # device in the usb tree
  @handle  = nil # device opened
  @devices = []

  # Finds supported amBX devices in the current USB device tree.
  #
  # @return [Boolean] true when at least one supported device was found.
  def self.connect
    @devices = []

    @context ||= LIBUSB::Context.new
    @context.devices.select do |dev|
      Protocol.supported_usb_device?(dev.idVendor, dev.idProduct)
    end.each do |dev|
      if @device.nil?
        @device = dev
      end

      @devices << dev

      true
    end

    !@devices.empty?
  end

  # Opens and claims all currently discovered devices.
  #
  # Attempts `connect` when no cached devices are present.
  #
  # @return [Boolean] true when all handles were opened and claimed.
  def self.open
    return false if (@devices.nil? || @devices.all? { |dev| dev.nil? }) && !Ambx.connect

    @handles = @devices.map { |device| device.open }
    return false if @handles.any? { |handle| handle.nil? }

    return true if @handles.all? { |handle| Ambx.claim_interface(handle) }

    Ambx.close
    false
  end

  # Claims interface 0 on an opened USB handle.
  #
  # Retries up to three times with kernel-driver auto-detach enabled.
  #
  # @param handle [LIBUSB::DeviceHandle] Open device handle.
  # @return [Boolean] true when claimed successfully, otherwise false.
  def self.claim_interface(handle)
    max_attempts = 4
    max_attempts.times do |attempt|
      begin
        error_code = handle.claim_interface(0)
      rescue ArgumentError
        error_code = nil
      end

      return true unless error_code.nil?

      if attempt < max_attempts - 1
        handle.auto_detach_kernel_driver = true
      else
        return false
      end
    end
  end

  # Closes all open handles and resets internal connection state.
  #
  # @param clearLights [Boolean] Whether to turn all light zones off before closing.
  # @return [void]
  def self.close(clearLights = false)
    return if @handles.nil? || @handles.all? { |handle| handle.nil? }

    Ambx.clear_lights if clearLights

    @handles.each { |handle| Ambx.close_device(handle) }

    @device  = nil
    @handles = nil
    @devices = []
  end

  # Closes a single device handle.
  #
  # @param handle [LIBUSB::DeviceHandle] Open device handle.
  # @return [void]
  def self.close_device(handle)
    return if handle.nil?

    begin
      handle.close
    rescue Errno::ENXIO
    end
  end

  # Sends all-off packets for all known light zones.
  #
  # @return [void]
  def self.clear_lights
    Ambx.write(Packet.set_color(Ambx::Lights::LEFT, 0, 0, 0))
    Ambx.write(Packet.set_color(Ambx::Lights::WWLEFT, 0, 0, 0))
    Ambx.write(Packet.set_color(Ambx::Lights::WWCENTER, 0, 0, 0))
    Ambx.write(Packet.set_color(Ambx::Lights::WWRIGHT, 0, 0, 0))
    Ambx.write(Packet.set_color(Ambx::Lights::RIGHT, 0, 0, 0))
  end

  # Writes bytes to the USB device.
  # Sends the provided bytes to all currently opened device handles.
  # If no handles are available, the call performs no action.
  #
  # @param [Packet, Array<Integer>] bytes_or_packet Packet or raw byte sequence to send.
  # @return [void]
  # @example Set WW center light to green
  #   Ambx.write(Ambx::Packet.set_color(Ambx::Lights::WWCENTER, 0x00, 0xFF, 0x00))
  def self.write(bytes_or_packet)
    return if @handles.nil? || @handles.all? { |handle| handle.nil? } # we lost it. see issue #1 on google code.

    bytes = bytes_or_packet.is_a?(Packet) ? bytes_or_packet.to_a : bytes_or_packet

    @handles.each do |handle|
      next if handle.nil?

      Ambx.write_device(handle, bytes)
    end
  end

  # Sends bytes to a single USB handle using interrupt transfer.
  #
  # If ENXIO is raised, all handles are closed to force a clean reconnect path.
  #
  # @param handle [LIBUSB::DeviceHandle] Open device handle.
  # @param bytes [Array<Integer>] Raw packet bytes.
  # @return [void]
  def self.write_device(handle, bytes)
    handle.interrupt_transfer(
      endpoint: Protocol::ENDPOINT_OUT,
      dataOut: bytes.pack("C*"),
      timeout: 0
    )
    # quick fix to not immediately segfault, but wait for segfault when application quits.
    # need a fix somewhere in ruby_usb, see issue #1 on google code.
  rescue Errno::ENXIO
    Ambx.close
  end

  # Reconnect to the device, retrying up to max_attempts times with a delay between attempts.
  #
  # @param max_attempts [Integer] Maximum number of connection attempts.
  # @param delay [Numeric] Seconds to wait between attempts.
  # @return [Boolean] true if reconnected successfully, false otherwise.
  def self.reconnect!(max_attempts: 3, delay: 1.0)
    max_attempts.times do |i|
      return true if connect && open
      sleep(delay) if i < max_attempts - 1
    end
    false
  end
end
