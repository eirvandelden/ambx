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
require_relative "menubar_helpers"

# Load configuration (colors, fan speeds, and green boost)
CONFIG     = YAML.safe_load_file(CONFIG_PATH)
COLORS     = CONFIG["colors"]
FAN_SPEEDS = CONFIG["fan_speeds"]
GREEN_BOOST = CONFIG["green_boost"] || 1.0

# Initialize USB connection — must both enumerate AND open/claim the device
connected = init_ambx

# Print initial menu
print_menu(connected)

# Handle menu selections
while (selection = gets&.chomp)
  case selection
  when STRINGS[:turn_off]
    connected = Ambx.connect && Ambx.open ? set_all_lights(0, 0, 0) : false
  when STRINGS[:quit]
    exit
  else
    fan = FAN_SPEEDS.find { |f| f["name"] == selection }
    if fan
      connected = Ambx.connect && Ambx.open ? set_fan_speed(fan["speed"]) : false
    else
      color = COLORS.find { |c| c["name"] == selection }
      connected = Ambx.connect && Ambx.open ? set_all_lights(*color["rgb"]) : false if color
    end
  end
  print_menu(connected)
end
