module RotaryDecoder
  # TODO: fill in after USB capture (Phase 1)
  # Expected: returns { type: :volume, delta: +1/-1 } or { type: :brightness, delta: +1/-1 }
  # Returns nil for unrecognized packets.

  VOLUME_EVENT_TYPE     = nil  # TBD
  BRIGHTNESS_EVENT_TYPE = nil  # TBD

  def self.decode(bytes)
    return nil if bytes.nil? || bytes.empty?
    # raw = bytes.unpack("C*")
    nil
  end
end
