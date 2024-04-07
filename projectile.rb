class Projectile
  GFX = Gosu::Image.new('./gfx/projectile.png', retro: true)

  attr_reader :x, :y, :w, :h, :angle 
  attr_accessor :to_delete

  def initialize(x, y, angle, speed = 0.8, power = 1, color = Gosu::Color::WHITE)
    @x, @y, @angle, @speed, @power, @color = x, y, angle, speed, power, color
    @w, @h = @power * GFX.width, @power * GFX.height 
    @to_delete = false
  end

  def update(delta)
    speed = delta * @speed
    @x += Gosu.offset_x(@angle, speed)
    @y += Gosu.offset_y(@angle, speed)
  end

  def draw
    GFX.draw_rot(@x, @y, 1, 0, 0.5, 0.5, @power, @power, @color)
  end
end