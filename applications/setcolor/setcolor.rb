require_relative "../../lib/libambx"

puts "\n🌈 setcolor — splash some color onto your Philips amBX lights.\n"
puts "Enjoy the glow! ✨\n\n"

if Ambx.connect
  if Ambx.open
    Ambx.write_all([ 0xA1, Lights::LEFT, 0x03, Integer(ARGV[0]), Integer(ARGV[1]), Integer(ARGV[2]) ])
    Ambx.write_all([ 0xA1, Lights::WWLEFT, 0x03, Integer(ARGV[0]), Integer(ARGV[1]), Integer(ARGV[2]) ])
    Ambx.write_all([ 0xA1, Lights::WWCENTER, 0x03, Integer(ARGV[0]), Integer(ARGV[1]), Integer(ARGV[2]) ])
    Ambx.write_all([ 0xA1, Lights::WWRIGHT, 0x03, Integer(ARGV[0]), Integer(ARGV[1]), Integer(ARGV[2]) ])
    Ambx.write_all([ 0xA1, Lights::RIGHT, 0x03, Integer(ARGV[0]), Integer(ARGV[1]), Integer(ARGV[2]) ])

    Ambx.write_all([ 0xA1, Lights::LEFT_FAN, 0x03, 0, 0, 0 ])
    Ambx.write_all([ 0xA1, Lights::RIGHT_FAN, 0x03, 0, 0, 0 ])
    Ambx.close
  else
    puts "Unable to open the discovered device"
  end
else
  puts "Unable to find a ambx device"
end
