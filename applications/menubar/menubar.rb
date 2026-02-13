#!/usr/bin/env ruby

# Handle paths for both development and Platypus bundle
if File.exist?(File.join(__dir__, "libcombustd"))
  # Running in Platypus bundle - files are in Resources/
  require_relative "libcombustd/libcombustd"
  CONFIG_PATH = File.join(__dir__, "colors.yml")
else
  # Running in development - use relative paths to project structure
  require_relative "../../libcombustd/libcombustd"
  CONFIG_PATH = File.join(__dir__, "config/colors.yml")
end

require "yaml"

# Load configuration (colors, fan speeds, and green boost)
CONFIG = YAML.safe_load_file(CONFIG_PATH)
COLORS = CONFIG["colors"]
FAN_SPEEDS = CONFIG["fan_speeds"]
GREEN_BOOST = CONFIG["green_boost"] || 1.0

# Initialize USB connection
def init_ambx
  return true if Ambx.connect && Ambx.open
  false
end

# Set all lights to color (sent to both Ambx devices automatically)
# Applies green boost to compensate for dimmer green LEDs
def set_all_lights(r, g, b)
  # Boost green channel and cap at 255
  g_boosted = [ g * GREEN_BOOST, 255 ].min.round

  [ Lights::LEFT, Lights::WWLEFT, Lights::WWCENTER,
   Lights::WWRIGHT, Lights::RIGHT ].each do |light_id|
    Ambx.write([ 0xA1, light_id, 0x03, r, g_boosted, b ])
  end
  Ambx.close
end

# Set fan speed (0-255) - user has 1 set of fans (LEFT_FAN)
def set_fan_speed(speed)
  Ambx.write([ 0xA1, Lights::LEFT_FAN, 0x03, 0, 0, speed ])
  Ambx.close
end

# Output menu structure
def print_menu(connected)
  status = connected ? "✓ Connected" : "⚠️ Disconnected"
  puts "Ambx Lights (#{status})"
  puts "---"
  puts "Turn Off Lights" if connected
  puts "---" if connected

  COLORS.each { |color| puts color["name"] }

  if connected
    puts "---"
    FAN_SPEEDS.each { |fan| puts fan["name"] }
  end

  puts "---"
  puts "QUIT"
end

# Main loop
connected = Ambx.connect && Ambx.open

# Print initial menu
print_menu(connected)

# Handle menu selections
while (selection = gets&.chomp)
  case selection
  when "Turn Off Lights"
    # Attempt to open connection with reconnection fallback
    if Ambx.connect && Ambx.open
      set_all_lights(0, 0, 0)
      connected = true
    else
      connected = false
    end
  when "QUIT"
    exit
  else
    # Check if it's a fan speed selection
    fan = FAN_SPEEDS.find { |f| f["name"] == selection }
    if fan
      # Attempt to open connection with reconnection fallback
      if Ambx.connect && Ambx.open
        set_fan_speed(fan["speed"])
        connected = true
      else
        connected = false
      end
    else
      # Check if it's a color selection
      color = COLORS.find { |c| c["name"] == selection }
      if color
        # Attempt to open connection with reconnection fallback
        if Ambx.connect && Ambx.open
          set_all_lights(*color["rgb"])
          connected = true
        else
          connected = false
        end
      end
    end
  end

  print_menu(connected)
end
