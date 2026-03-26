# Helper functions and constants for the Ambx menubar

MAX_RECONNECT_ATTEMPTS = 1

STRINGS = {
  title:        "Ambx Lights",
  connected:    "✓ Connected",
  disconnected: "⚠️ Disconnected",
  turn_off:     "Turn Off Lights",
  quit:         "QUIT"
}.freeze

# Initialize USB connection
def init_ambx
  Ambx.connect && Ambx.open
end

# Set all lights to color (sent to both Ambx devices automatically)
# Applies green boost to compensate for dimmer green LEDs
# Returns true if all lights were set successfully, false if connection was lost mid-write
def set_all_lights(r, g, b)
  g_boosted       = [ g * GREEN_BOOST, 255 ].min.round
  reconnect_attempts = 0

  loop do
    lost = false
    [ Lights::LEFT, Lights::WWLEFT, Lights::WWCENTER,
      Lights::WWRIGHT, Lights::RIGHT ].each do |light_id|
      Ambx.write([ 0xA1, light_id, 0x03, r, g_boosted, b ])
      unless Ambx.connected?
        lost = true
        break
      end
    end

    unless lost
      Ambx.close
      return true
    end

    reconnect_attempts += 1
    return false if reconnect_attempts > MAX_RECONNECT_ATTEMPTS
    return false unless Ambx.connect && Ambx.open
  end
end

# Set fan speed (0-255) for both fans
# Returns true if fan speed was set successfully, false if connection was lost
def set_fan_speed(speed)
  reconnect_attempts = 0

  loop do
    lost = false
    [ Lights::LEFT_FAN, Lights::RIGHT_FAN ].each do |fan_id|
      Ambx.write([ 0xA1, fan_id, 0x03, 0, 0, speed ])
      unless Ambx.connected?
        lost = true
        break
      end
    end

    unless lost
      Ambx.close
      return true
    end

    reconnect_attempts += 1
    return false if reconnect_attempts > MAX_RECONNECT_ATTEMPTS
    return false unless Ambx.connect && Ambx.open
  end
end

# Output menu structure
def print_menu(connected)
  status = connected ? STRINGS[:connected] : STRINGS[:disconnected]
  puts "#{STRINGS[:title]} (#{status})"
  puts "---"
  puts STRINGS[:turn_off] if connected
  puts "---" if connected
  COLORS.each { |color| puts color["name"] }
  if connected
    puts "---"
    FAN_SPEEDS.each { |fan| puts fan["name"] }
  end
  puts "---"
  puts STRINGS[:quit]
end
