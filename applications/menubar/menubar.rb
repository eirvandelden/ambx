#!/usr/bin/env ruby

# Disable output buffering for Platypus Status Menu
$stdout.sync = true
$stderr.sync = true

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
# Returns true if all lights were set successfully, false if connection was lost mid-write
def set_all_lights(r, g, b)
  # Boost green channel and cap at 255
  g_boosted = [ g * GREEN_BOOST, 255 ].min.round

  [ Lights::LEFT, Lights::WWLEFT, Lights::WWCENTER,
   Lights::WWRIGHT, Lights::RIGHT ].each do |light_id|
    Ambx.write([ 0xA1, light_id, 0x03, r, g_boosted, b ])

    # Check if connection was lost mid-write (error handler called Ambx.close)
    # If so, reconnect and retry the full sequence to ensure all lights match
    unless Ambx.connected?
      return false unless Ambx.connect && Ambx.open
      # Retry from the beginning to ensure consistent state across all lights
      return set_all_lights(r, g, b)
    end
  end
  Ambx.close
  true
end

# Set fan speed (0-255) for both fans
# Returns true if fan speed was set successfully, false if connection was lost
def set_fan_speed(speed)
  [ Lights::LEFT_FAN, Lights::RIGHT_FAN ].each do |fan_id|
    Ambx.write([ 0xA1, fan_id, 0x03, 0, 0, speed ])

    # Check if connection was lost during write
    unless Ambx.connected?
      return false unless Ambx.connect && Ambx.open
      # Retry from the beginning to keep both fans in sync
      return set_fan_speed(speed)
    end
  end

  Ambx.close
  true
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
connected = Ambx.connect

# Print initial menu
print_menu(connected)

# Handle menu selections
while (selection = gets&.chomp)
  case selection
  when "Turn Off Lights"
    # Attempt to open connection with reconnection fallback
    if Ambx.connect && Ambx.open
      connected = set_all_lights(0, 0, 0)
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
        connected = set_fan_speed(fan["speed"])
      else
        connected = false
      end
    else
      # Check if it's a color selection
      color = COLORS.find { |c| c["name"] == selection }
      if color
        # Attempt to open connection with reconnection fallback
        if Ambx.connect && Ambx.open
          connected = set_all_lights(*color["rgb"])
        else
          connected = false
        end
      end
    end
  end

  print_menu(connected)
end
