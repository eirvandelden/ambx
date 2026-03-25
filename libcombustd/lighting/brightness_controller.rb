module BrightnessController
  STEP = 0.05
  @level = 1.0

  def self.level = @level

  def self.adjust(delta)
    @level = (@level + delta * STEP).clamp(0.0, 1.0)
    Ambx.reapply_brightness
  end

  def self.apply(r, g, b)
    [ (r * @level).round, (g * @level).round, (b * @level).round ]
  end
end
