require "vips"
require "thread"

# Define the number of zones (10 in this case)
ZONE_COUNT          = 5
PIXEL_SAMPLING_RATE = 20 # Process every nth pixel for performance

# Load the AmBX library
require_relative "../../libcombustd/libcombustd"

# Capture a screenshot and load it into memory
def capture_screenshot
  screenshot_path = "screenshot.png"

  # Use macOS's screencapture command to take a screenshot
  system("screencapture -x #{screenshot_path}") # `-x` prevents user interaction

  # Load the screenshot into memory using ruby-vips
  image = Vips::Image.new_from_file(screenshot_path)
  image.resize(0.5) # Resize for performance (adjust scale as needed)
  image
end

# Calculate the average color of a given region in the image
def average_color(image, x_start, y_start, width, height)
  total_r     = 0
  total_g     = 0
  total_b     = 0
  pixel_count = 0

  # Only sample every nth pixel for performance
  (y_start...y_start + height).step(PIXEL_SAMPLING_RATE).each do |y|
    (x_start...x_start + width).step(PIXEL_SAMPLING_RATE).each do |x|
      pixel   = image.getpoint(x, y)
      r, g, b = pixel[0], pixel[1], pixel[2]

      total_r     += r
      total_g     += g
      total_b     += b
      pixel_count += 1
    end
  end

  avg_r = (total_r / pixel_count).round
  avg_g = (total_g / pixel_count).round
  avg_b = (total_b / pixel_count).round

  [avg_r, avg_g, avg_b]
end

# Divide the screen into zones and calculate the average color for each
def calculate_zone_colors(image)
  # Get the screen dimensions
  screen_width  = image.width
  screen_height = image.height

  # Divide the screen width into zones
  zone_width  = screen_width / ZONE_COUNT
  zone_height = screen_height

  zone_colors = Array.new(ZONE_COUNT)
  # threads     = []

  (0...ZONE_COUNT).each do |i|
    # threads << Thread.new do
      x_start        = i * zone_width
      y_start        = 0 # Full height of the screen for each zone
      zone_colors[i] = average_color(image, x_start, y_start, zone_width, zone_height)
    # end
  end

  # Wait for all threads to finish
  # threads.each(&:join)
  zone_colors
end

# Update lights using the AmBX repository
def update_lights(zone_colors)
    if Ambx.open
      light_mapping = {
        "0": Lights::LEFT,
        "1": Lights::WWLEFT,
        "2": Lights::WWCENTER,
        "3": Lights::WWRIGHT,
        "4": Lights::RIGHT
      }
      zone_colors.each_with_index do |color, index|
        r, g, b = color
        # Assuming AmBX has a method `set_light(zone, r, g, b)` to update light colors
        Ambx.write([light_mapping[index.to_s.to_sym], 0x03, r, g, b]) # Send the RGB color to the corresponding light
      end
      Ambx.close
    end
end

# Graceful shutdown flag
@running = true

# Signal handling for graceful shutdown
Signal.trap("INT") do
  puts "\nSIGINT received. Stopping the script gracefully..."
  @running = false
end

Signal.trap("TERM") do
  puts "\nSIGTERM received. Stopping the script gracefully..."
  @running = false
end

# Main script loop
if Ambx.connect
  while @running
    begin
      # Capture a new screenshot
      image = capture_screenshot

      # Calculate average colors for each zone
      zone_colors = calculate_zone_colors(image)

      # Update lights using the AmBX repository
      update_lights(zone_colors)

      # Add a delay to control how often the script runs (e.g., 500ms)
      sleep(0.5) # Adjust this delay as needed
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
end

puts "Script terminated."
