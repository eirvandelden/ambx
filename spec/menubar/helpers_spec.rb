require "minitest/autorun"

# ---------------------------------------------------------------------------
# Stubs — must be defined BEFORE requiring menubar_helpers so the constant
# references resolve at call time, not at require time.
# ---------------------------------------------------------------------------

class Lights
  LEFT      = 0x0B
  WWLEFT    = 0x2B
  WWCENTER  = 0x3B
  WWRIGHT   = 0x4B
  RIGHT     = 0x1B
  LEFT_FAN  = 0x5B
  RIGHT_FAN = 0x6B
end

COLORS      = [ { "name" => "Warm White", "rgb" => [ 255, 244, 229 ] } ]
FAN_SPEEDS  = [ { "name" => "Fan: Low", "speed" => 64 } ]
GREEN_BOOST = 1.0

# Controllable Ambx stub
module AmbxStub
  @connect    = true
  @open       = true
  @connected  = true
  @write_log  = []

  class << self
    attr_accessor :connect, :open, :connected
    attr_reader :write_log

    def reset!
      @connect   = true
      @open      = true
      @connected = true
      @write_log = []
    end

    def connect  = @connect
    def open     = @open
    def connected? = @connected
    def write(bytes) = @write_log << bytes
    def close    = nil
  end
end

# Point the global Ambx constant at our stub
Ambx = AmbxStub

require_relative "../../applications/menubar/menubar_helpers"

# ---------------------------------------------------------------------------
class MenubarHelpersTest < Minitest::Test
  def setup
    AmbxStub.reset!
  end
end
