# Definitions so we do not need to remember the hex values for the lights
class Lights
  # LEFT/RIGHT lights. Normally placed adjecent to your screen.
  LEFT  = 0x0B
  RIGHT = 0x1B

  # Wallwasher lights. Normally placed behind your screen.
  WWLEFT   = 0x2B
  WWCENTER = 0x3B
  WWRIGHT  = 0x4B

  # Fans
  LEFT_FAN  = 0x5B
  RIGHT_FAN = 0x6B

  # Keyboard rumble
  RUMBLE = 0x7B
end
