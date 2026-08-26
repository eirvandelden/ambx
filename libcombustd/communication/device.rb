class Ambx
  class Device
    CLEAR_LIGHTS = [ Lights::LEFT, Lights::WWLEFT, Lights::WWCENTER, Lights::WWRIGHT, Lights::RIGHT ].freeze

    def initialize(descriptor)
      @descriptor = descriptor
      @handle = nil
    end

    def identity
      return "serial:#{serial_number}" unless serial_number.to_s.empty?
      return "port:#{formatted_port_path}" unless formatted_port_path.empty?

      nil
    end

    def serial_number
      return @serial_number if defined?(@serial_number)

      @serial_number = @descriptor.serial_number
      @serial_number = nil if @serial_number == "?"
      @serial_number
    rescue NoMethodError, LIBUSB::ERROR_NOT_FOUND
      @serial_number = nil
    end

    def port_path
      return @port_path if defined?(@port_path)

      @port_path = @descriptor.port_path if @descriptor.respond_to?(:port_path)
      @port_path = @descriptor.port_numbers if empty_port_path?(@port_path) && @descriptor.respond_to?(:port_numbers)
      @port_path
    rescue NoMethodError
      @port_path = nil
    end

    def open
      return self if connected?

      handle = @descriptor.open
      return false if handle.nil?

      claim(handle)
    rescue StandardError
      close_handle(handle) if handle
      raise
    end

    def connected?
      !@handle.nil?
    end

    def write(bytes)
      return false unless connected?

      return true if transfer(@handle, bytes)

      close
      false
    end

    def close(clear_lights: false)
      handle = @handle
      return unless handle

      @handle = nil
      clear_all_lights(handle) if clear_lights
      close_handle(handle)
    end

    private

    def claim(handle)
      return close_unclaimed_handle(handle) unless Ambx.claim_interface(handle, retry_busy: true)

      @handle = handle
      self
    end

    def close_unclaimed_handle(handle)
      close_handle(handle)
      false
    end

    def clear_all_lights(handle)
      CLEAR_LIGHTS.each do |light|
        break unless transfer(handle, [ 0xA1, light, ProtocolDefinitions::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      end
    end

    def transfer(handle, bytes)
      handle.interrupt_transfer(
        endpoint: ProtocolDefinitions::ENDPOINT_OUT,
        dataOut: bytes.pack("C*"),
        timeout: 0
      )
      true
    rescue Errno::ENXIO
      false
    end

    def close_handle(handle)
      handle.close
    rescue Errno::ENXIO
    end

    def formatted_port_path
      path = port_path
      return "" if empty_port_path?(path)

      path.is_a?(Array) ? path.join(".") : path.to_s.tr("/", ".")
    end

    def empty_port_path?(path)
      path.nil? || (path.respond_to?(:empty?) && path.empty?)
    end
  end
end
