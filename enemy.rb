class Enemy
  @@font = Gosu::Font.new(24)
  @@sfx = {
    fire: Gosu::Sample.new('./sfx/Fire 5.mp3'),
    hit: Gosu::Sample.new('./sfx/Hit 1.mp3')
  }

  def initialize(window, x, y)
    @window = window
    @x, @y = x, y
    @projectiles = []
    @aabb_x, @aabb_y, @aabb_w, @aabb_h = 0, 0, 0, 0
    @to_delete = false
    @dying = false
    @lives = 1
  end

  def collides_projectile?(projectile)
    return false if @to_delete || @dying
    return false if projectile.x - projectile.w / 2 > @aabb_x + @aabb_w
    return false if projectile.x + projectile.w / 2 < @aabb_x
    return false if projectile.y - projectile.h / 2 > @aabb_y + @aabb_h
    return false if projectile.y + projectile.h / 2 < @aabb_y
    return true
  end

  def to_delete
    return true if @to_delete && @projectiles.empty?
  end

  def hit
    @lives -= 1
    if @lives <= 0
      @dying = true
    end
  end

  def draw
    # @@font.draw_text(@projectiles.size, @x, @y - 50, 10)
  end
end

class Soldier < Enemy
  attr_reader :x, :y, :projectiles
  def initialize(window, x, y)
      super(window, x, y)
      @arms_angle = 0
      @width, @height = 16, 32
  
      @parts = {
        body: Gosu::Image.new('./gfx/enemies/soldier/soldier_body.png', retro: true),
        arms: Gosu::Image.new('./gfx/enemies/soldier/soldier_arms.png', retro: true),
        leg: Gosu::Image.new('./gfx/enemies/soldier/soldier_leg.png', retro: true)
      }
      
      @shot_speed = 0.1
      @power = 1.0
      @cool_down = 600
      @fire_tick = Gosu::milliseconds
      @fire_distance = 200
      @shot_color = Gosu::Color::BLUE
    end
  
    def fire
      @projectiles.push Projectile.new(@x, @y + 5, @arms_angle, @shot_speed, @power, @shot_color)
      @@sfx[:fire].play(0.01)
    end
  
    def update(delta, hero)
      @projectiles.each do |projectile| 
        projectile.update(delta)

        if hero.collides_projectile?(projectile)
          hero.hit
          @@sfx[:hit].play(0.01)
          projectile.to_delete = true
        end
      end
  
      @projectiles.delete_if do |projectile| 
        projectile.to_delete ||
        (projectile.x > hero.aabb_x + hero.aabb_w / 2 + @window.width / 2) ||
        (projectile.x < hero.aabb_x - @window.width / 2) ||
        (projectile.y < -hero.aabb_y) ||
        (projectile.y > hero.aabb_y + hero.aabb_h / 2 + @window.height / 2) 
      end

      unless @to_delete || @dying
        mirror = (@arms_angle > 180)
        @arms_angle = Gosu::angle(@x + @width / 2, @y + @height / 2 + 5, hero.aabb_x + hero.aabb_w / 2, hero.aabb_y + hero.aabb_h / 2)

        if Gosu::distance(@x, @y, hero.aabb_x + hero.aabb_w / 2, hero.aabb_y + hero.aabb_h / 2) <= @fire_distance
          if Gosu::milliseconds - @fire_tick >= @cool_down
            fire
            @fire_tick = Gosu::milliseconds
          end
        end
      end

      if @dying
        unless defined?(@blood)
          @blood = []
          particles = Gosu.random(5, 15).to_i
          particles.times {@blood.push [@x, @y, Gosu.random(0, 359).to_i, Gosu.random(2, 5), Gosu.random(0.6, 1.0), Gosu::Color.new(255, 255, 0, 0)]}
        end

        @blood.each_with_index do |particle, i|
          x, y, angle, size, speed, color = particle
          x += Gosu.offset_x(angle, speed)
          y += Gosu.offset_y(angle, speed)
          color.alpha -= 4

          @blood[i] = [x, y, angle, size, speed, color]
          @to_delete = true if color.alpha == 0
        end
      end
    end
    
    def draw_aabb
      # Gosu.draw_rect(@aabb_x, @aabb_y, @aabb_w, @aabb_h, Gosu::Color::BLUE)
    end
  
    def draw
      unless @to_delete || @dying
        super 

        # body
        mirror = @arms_angle > 180 ? -1 : 1
    
        # body
        @parts[:body].draw_rot(@x, @y, 2, 0, 0.5, 0.5, mirror, 1)

        # AABB
        @aabb_x, @aabb_y, @aabb_w, @aabb_h = @x - @width / 2, @y - @height / 2, @width, @height
        draw_aabb
        
        # arms
        @parts[:arms].draw_rot(@x, @y + 8, 3, @arms_angle - 90.0, 0.1, 0.5, 1, mirror)
        # / aiming
        
        # feet
        @parts[:leg].draw_rot(@x - 2, @y + 6, 2, 0, 0.5, 0.1, mirror, 1)
        @parts[:leg].draw_rot(@x + 2, @y + 6, 2, 0, 0.5, 0.1, mirror, 1)
      end

      if @dying && defined?(@blood)
        @blood.each do |particle|
          x, y, angle, size, speed, color = particle
          Gosu.draw_rect(x, y, size, size, color)
        end
      end

      @projectiles.each {|projectile| projectile.draw}
    end
  end

  class Soldier2 < Soldier
    def initialize(window, x, y)
      super(window, x, y)

      @parts = {
        body: Gosu::Image.new('./gfx/enemies/soldier2/soldier2_body.png', retro: true),
        arms: Gosu::Image.new('./gfx/enemies/soldier2/soldier2_arms.png', retro: true),
        leg: Gosu::Image.new('./gfx/enemies/soldier2/soldier2_leg.png', retro: true)
      }
      
      @cool_down = 300
      @shot_speed = 0.2
      @fire_distance = 400
      @power = 1
      @shot_color = Gosu::Color.new(255, 178, 0, 255)
      @lives = 2
    end
  end

  class Boss < Soldier
    def initialize(window, x, y)
      super(window, x, y)

      @parts = {
        body: Gosu::Image.new('./gfx/enemies/boss/boss_body.png', retro: true),
        arms: Gosu::Image.new('./gfx/enemies/boss/boss_arms.png', retro: true),
        leg: Gosu::Image.new('./gfx/enemies/boss/boss_leg.png', retro: true)
      }
      
      @cool_down = 200
      @shot_speed = 0.25
      @fire_distance = 400
      @power = 2
      @shot_color = Gosu::Color::RED
      @lives = 5
    end
  end