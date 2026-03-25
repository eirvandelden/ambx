REQUIREMENTPATH = File.dirname(__FILE__)

# ruby-usb; http://www.a-k-r.org/ruby-usb/
# a ruby wrapper around libusb, needs to be compiled from source and gem installed.
require "libusb"

# Classes for definitions
require REQUIREMENTPATH + "/data/protocoldefinitions"
require REQUIREMENTPATH + "/data/lights"

# Classes for logic
require REQUIREMENTPATH + "/communication/ambx"

# Rotary gear support
require REQUIREMENTPATH + "/data/rotary_decoder"
require REQUIREMENTPATH + "/integration/macos"
require REQUIREMENTPATH + "/lighting/brightness_controller"
require REQUIREMENTPATH + "/communication/ambx_input"

# Classes for errors
class CannotClaimInterfaceError < StandardError; end
