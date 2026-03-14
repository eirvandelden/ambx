module Menubar
  class App
    def initialize(device:, lights:, fans:, colors:, fan_speeds:, green_boost:, input: $stdin, output: $stdout)
      @device = device
      @lights = lights
      @fans = fans
      @colors = colors
      @fan_speeds = fan_speeds
      @green_boost = green_boost
      @input = input
      @output = output
    end

    def run
      connected = connection_available?
      print_menu(connected)

      while (selection = @input.gets&.chomp)
        outcome = handle_selection(selection, connected: connected)
        break if outcome == :quit

        connected = outcome
        print_menu(connected)
      end
    end

    def connection_available?
      with_connection { nil }
    end

    def handle_selection(selection, connected:)
      return :quit if selection == "QUIT"
      return perform { set_all_lights(0, 0, 0) } if selection == "Turn Off Lights"

      fan = @fan_speeds.find { |entry| entry["name"] == selection }
      return perform { set_fan_speed(fan["speed"]) } if fan

      color = @colors.find { |entry| entry["name"] == selection }
      return perform { set_all_lights(*color["rgb"]) } if color

      connected
    end

    private

    def perform
      with_connection { yield }
    end

    def with_connection
      opened = @device.connect && @device.open
      return false unless opened

      yield
      true
    ensure
      @device.close if opened
    end

    def set_all_lights(r, g, b)
      boosted_green = [ g * @green_boost, 255 ].min.round

      [ @lights::LEFT, @lights::WWLEFT, @lights::WWCENTER, @lights::WWRIGHT, @lights::RIGHT ].each do |light_id|
        @device.write([ 0xA1, light_id, 0x03, r, boosted_green, b ])
      end
    end

    def set_fan_speed(speed)
      [ @fans::LEFT, @fans::RIGHT ].each do |fan_id|
        @device.write([ 0xA1, fan_id, 0x03, 0, 0, speed ])
      end
    end

    def print_menu(connected)
      status = connected ? "✓ Connected" : "⚠️ Disconnected"

      @output.puts "Ambx Lights (#{status})"
      @output.puts "---"
      @output.puts "Turn Off Lights" if connected
      @output.puts "---" if connected

      @colors.each { |color| @output.puts color["name"] }

      if connected
        @output.puts "---"
        @fan_speeds.each { |fan| @output.puts fan["name"] }
      end

      @output.puts "---"
      @output.puts "QUIT"
    end
  end
end
