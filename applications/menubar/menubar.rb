#!/usr/bin/env ruby

require "yaml"
require_relative "app"
require_relative "boot"

Menubar::Boot.load_dependencies(__dir__)

config = YAML.safe_load_file(Menubar::Boot.config_path(__dir__))

Menubar::App.new(
  device: Ambx,
  lights: Ambx::Lights,
  fans: Ambx::Fans,
  colors: config.fetch("colors"),
  fan_speeds: config.fetch("fan_speeds"),
  green_boost: config["green_boost"] || 1.0
).run
