REQUIREMENTPATH = File.dirname(__FILE__)

# Gem version
require "#{REQUIREMENTPATH}/version"

# ruby-usb; http://www.a-k-r.org/ruby-usb/
# a ruby wrapper around libusb, needs to be compiled from source and gem installed.
require 'libusb'

# Namespaced data definitions
require "#{REQUIREMENTPATH}/data/protocoldefinitions"
require "#{REQUIREMENTPATH}/data/lights"
require "#{REQUIREMENTPATH}/data/fans"
require "#{REQUIREMENTPATH}/data/rumbler"

# Core driver
require "#{REQUIREMENTPATH}/communication/ambx"

# Value objects
require "#{REQUIREMENTPATH}/ambx/packet"
