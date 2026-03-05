class Ambx
  # Value object encapsulating a 6-byte amBX USB packet.
  # Centralises packet construction so the 0xA1 preamble is always present
  # and byte values are always clamped to 0..255.
  #
  # @example
  #   pkt = Ambx::Packet.set_color(Ambx::Lights::WWCENTER, 128, 0, 255)
  #   Ambx.write(pkt)
  class Packet
    # Raw packet bytes.
    #
    # @return [Array<Integer>]
    attr_reader :bytes

    # Build a SET_LIGHT_COLOR packet.
    # @param light_id [Integer] Light address constant from Ambx::Lights.
    # @param r [Numeric] Red channel (0–255, floats are rounded and clamped).
    # @param g [Numeric] Green channel.
    # @param b [Numeric] Blue channel.
    # @return [Packet]
    def self.set_color(light_id, r, g, b)
      new([ 0xA1, light_id, Protocol::SET_LIGHT_COLOR, clamp(r), clamp(g), clamp(b) ])
    end

    # Build a SET_FAN_SPEED packet (speed in the blue channel per hardware convention).
    # @param fan_id [Integer] Fan address constant from Ambx::Fans (LEFT / RIGHT).
    # @param speed [Numeric] Fan speed (0–255, floats are rounded and clamped).
    # @return [Packet]
    def self.set_fan(fan_id, speed)
      new([ 0xA1, fan_id, Protocol::SET_LIGHT_COLOR, 0, 0, clamp(speed) ])
    end

    # @return [Array<Integer>] Copy of the raw byte array.
    def to_a
      @bytes.dup
    end

    # Creates a packet from prebuilt bytes.
    #
    # @param bytes [Array<Integer>] Six-byte packet payload.
    # @return [void]
    def initialize(bytes)
      @bytes = bytes.freeze
    end

    class << self
      private

      # Rounds and clamps a numeric byte value into the valid USB byte range.
      #
      # @param value [Numeric] Candidate byte value.
      # @return [Integer] Value constrained to 0..255.
      def clamp(value)
        value.round.clamp(0, 255)
      end
    end
  end
end
