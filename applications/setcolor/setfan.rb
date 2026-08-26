require_relative "../../lib/libambx"

puts "\n💨 setfan — command the winds within your Philips amBX setup.\n"
puts "Feel the breeze! 🌀\n\n"

if Ambx.connect
  if Ambx.open
    Ambx.write_all([ 0xA1, Lights::LEFT_FAN, 0x03, 0, 0, Integer(ARGV[0]) ])
    Ambx.write_all([ 0xA1, Lights::RIGHT_FAN, 0x03, 0, 0, Integer(ARGV[0]) ])

    Ambx.close
  else
    puts "Unable to open the discovered device"
  end
else
  puts "Unable to find a ambx device"
end
