module MacOSIntegration
  VOLUME_STEP = 5  # percent per tick

  def self.adjust_volume(delta)
    current = `osascript -e 'output volume of (get volume settings)'`.strip.to_i
    new_vol = (current + delta * VOLUME_STEP).clamp(0, 100)
    system("osascript", "-e", "set volume output volume #{new_vol}")
  end
end
