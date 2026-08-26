# ruby-usb; http://www.a-k-r.org/ruby-usb/
# a ruby wrapper around libusb, needs to be compiled from source and gem installed.
require "libusb"

# Classes for definitions
require_relative "data/protocoldefinitions"
require_relative "data/lights"

# Classes for logic
require_relative "communication/ambx"
