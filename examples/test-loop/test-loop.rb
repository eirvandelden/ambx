# test-loop
# loops a green light from left to right, and then a blue one from right to left

# put in our requirements.
require "../../libambx/libambx"

puts "\nRunning test-loop\n"

# Some dummy code to test the Ambx interface
# try to connect and open the device and then loop trough some colors.

if Ambx.connect
  if Ambx.open
    while true
      # First half of loop, GREEN from left to right
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0xFF, 0x00 ])
      sleep 1
      # All red
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      # Second half of loop BLUE from right to left
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0xFF ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0xFF ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0xFF ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0xFF ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0xFF ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      # All red
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0xCC, 0x00, 0x00 ])
      sleep 1
      # Turn off all lights
      Ambx.write([ 0xA1, Ambx::Lights::LEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWLEFT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWCENTER, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::WWRIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      Ambx.write([ 0xA1, Ambx::Lights::RIGHT, Ambx::Protocol::SET_LIGHT_COLOR, 0x00, 0x00, 0x00 ])
      sleep 1
    end
    Ambx.close true
  else
    puts "Unable to open the discovered device"
  end
else
  puts "Unable to find a ambx device"
end
