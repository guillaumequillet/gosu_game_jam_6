class Hero
  attr_reader :x, :y, :projectiles, :aabb_x, :aabb_y, :aabb_w, :aabb_h, :lives
  def initialize(window, x, y)
    @window = window
    @floor = y
    @origin_x, @origin_y = x, y
    @x, @y = x, y
    @aabb_x, @aabb_y, @aabb_w, @aabb_h = 0, 0, 0, 0
    @arms_angle = 0
    @walk_angle = 0
    @walk_angle_max = 30
    @walk_clock = 1
    @bounce = 0
    @bounce_max = 1
    @bounce_clock = 1
    @ray = 0
    @width, @height = 16, 32

    @keys = {
      right: Gosu::KB_RIGHT,
      left: Gosu::KB_LEFT,
      crouch: Gosu::KB_DOWN,
      shoot: Gosu::MS_LEFT,
      jump: Gosu::KB_UP
    }

    @crouched = false
    @jumping = false
    @max_jump = 90
    @jump_velocity = 0.4
    @current_jump_velocity = 0

    @parts = {
      aim: Gosu::Image.new('./gfx/aim.png', retro: true),
      body: Gosu::Image.new('./gfx/hero/hero_body.png', retro: true),
      arms: Gosu::Image.new('./gfx/hero/hero_arms.png', retro: true),
      leg: Gosu::Image.new('./gfx/hero/hero_leg.png', retro: true)
    }

    @sfx = {
      fire: Gosu::Sample.new('./sfx/Fire 1.mp3'),
      hit: Gosu::Sample.new('./sfx/Hit 1.mp3'),
      jump: Gosu::Sample.new('./sfx/sfx_jump_07-80241.mp3')
    }

    @projectiles = []
    @power = 1
    @shot_speed = 0.9
    @cool_down = 50
    @fire_tick = Gosu::milliseconds
    @lives = 5
    @blood = []
    @death_cooldown = 500
    @death_tick = Gosu::milliseconds
  end

  def button_down(id)
    if id == @keys[:shoot] && !@dying
      if Gosu::milliseconds - @fire_tick >= @cool_down
        fire
        @fire_tick = Gosu::milliseconds 
      end
    end

    if id == @keys[:jump] && !@jumping && !@dying
      @crouched = false
      jump
    end
  end

  def jump
    @sfx[:jump].play(0.3)
    @jumping = true
    @current_jump_velocity = @jump_velocity
  end

  def hit
    if !@dying && Gosu::milliseconds - @death_tick >= @death_cooldown
      @lives -= 1
      @dying = true
      @death_cooldown = Gosu::milliseconds
      @sfx[:hit].play(0.5)
    end
  end

  def collides_projectile?(projectile)
    return false if projectile.x - projectile.w / 2 > @aabb_x + @aabb_w
    return false if projectile.x + projectile.w / 2 < @aabb_x
    return false if projectile.y - projectile.h / 2 > @aabb_y + @aabb_h
    return false if projectile.y + projectile.h / 2 < @aabb_y
    return true
  end

  def fire
    y = @crouched ? @y + 9 : @y + 5
    @projectiles.push Projectile.new(@x, y, @arms_angle, @shot_speed, @power)
    @sfx[:fire].play(0.3)
  end

  def update(delta, mouse_x, mouse_y)
    if @dying
      if @blood.empty?
        @blood = []
        particles = Gosu.random(5, 15).to_i
        particles.times {@blood.push [@x, @y, Gosu.random(0, 359).to_i, Gosu.random(2, 5), Gosu.random(0.2, 1.0), Gosu::Color.new(255, 255, 0, 0)]}
      end

      @blood.each_with_index do |particle, i|
        x, y, angle, size, speed, color = particle
        x += Gosu.offset_x(angle, speed)
        y += Gosu.offset_y(angle, speed)
        color.alpha -= 2

        @blood[i] = [x, y, angle, size, speed, color]

        if color.alpha == 0
          @dying = false
          @blood = []
          @x = @origin_x
          @y = @origin_y
          @jumping = false
          @window.map.load_map
        end
      end

      return
    end

    mirror = (@arms_angle > 180)

    speed = 0.3
    backward_ratio = 0.6
    anim_speed = @walk_clock * 0.3
    bounce_speed = @bounce_clock * 0.01

    target_x, target_y = mouse_x + @x - @window.width / 2, mouse_y + @y - @window.height / 2
    @arms_angle = Gosu::angle(@x, @y, target_x, target_y)
    @ray = Gosu::distance(@x, @y, target_x, target_y)

    # can we crouch ?
    if Gosu::button_down?(@keys[:crouch]) && !@jumping
      @crouched = true
    else
      @crouched = false
    end
      
    if @jumping
      @y -= @current_jump_velocity * delta
      
      if Gosu::button_down?(@keys[:right])
        @x += speed * delta 
      elsif Gosu::button_down?(@keys[:left])
        @x -= speed * delta
      end 

      if @y <= @floor - @max_jump
        @current_jump_velocity *= -1
      elsif @y >= @floor
        @jumping = false
        @y = @floor
      end
    elsif !@crouched
      if Gosu::button_down?(@keys[:right])
        speed *= backward_ratio if mirror
        @x += speed * delta 
        @walk_angle += anim_speed * delta
        @bounce += bounce_speed * delta
      elsif Gosu::button_down?(@keys[:left]) 
        speed *= backward_ratio if !mirror
        @x -= speed * delta
        @walk_angle += anim_speed * delta
        @bounce += bounce_speed * delta
      else
        @walk_angle = 0
        @bounce = 0
      end

      @walk_clock = @walk_clock * -1 if (@walk_clock == -1 && @walk_angle <= -@walk_angle_max) || (@walk_clock == 1 && @walk_angle >= @walk_angle_max)
      @bounce_clock = @bounce_clock * -1 if (@bounce_clock == -1 && @bounce <= -@bounce_max) || (@bounce_clock == 1 && @bounce >= @bounce_max)
    end

    @x = @window.map.min + @width / 2 if @x < @window.map.min + @width / 2
    @x = @window.map.max - @width / 2 if @x > @window.map.max - @width / 2

    if @crouched
      @aabb_x, @aabb_y, @aabb_w, @aabb_h = @x - @width / 2, @y, @width, @height / 2
    else
      @aabb_x, @aabb_y, @aabb_w, @aabb_h = @x - @width / 2, @y - @height / 2, @width, @height
    end

    @projectiles.each do |projectile| 
      projectile.update(delta)

      @window.map.enemies.each do |enemy|
        if enemy.collides_projectile?(projectile)
          @sfx[:hit].play
          enemy.hit
          projectile.to_delete = true
        end
      end
    end

    @projectiles.delete_if do |projectile|
      projectile.to_delete || 
      (projectile.x > @x + @window.width / 2) ||
      (projectile.x < @x - @window.width / 2) ||
      (projectile.y < -@y) ||
      (projectile.y > @y + @window.height / 2) 
    end
  end
  
  def draw_aabb
    # Gosu.draw_rect(@aabb_x, @aabb_y, @aabb_w, @aabb_h, Gosu::Color::BLUE)
  end

  def draw
    if @dying && defined?(@blood)
      @blood.each do |particle|
        x, y, angle, size, speed, color = particle
        Gosu.draw_rect(x, y, size, size, color)
      end

      return
    end

    # body
    mirror = @arms_angle > 180 ? -1 : 1

    if @crouched
      # body
      @parts[:body].draw_rot(@x + mirror * 4, @y + 8, 2, 75 * mirror, 0.5, 0.5, mirror, 1)

      # AABB
      draw_aabb

      # feet
      @parts[:leg].draw_rot(@x - 2, @y + 13, 2, 90 * mirror, 0.5, 0.1, mirror, 1)
      @parts[:leg].draw_rot(@x + 2, @y + 13, 2, 90 * mirror, 0.5, 0.1, mirror, 1)      

      # laser
      aim_x = @x + Gosu::offset_x(@arms_angle, @ray)
      aim_y = @y + 8 + Gosu::offset_y(@arms_angle, @ray)
      color = Gosu::Color::RED
      Gosu.draw_line(@x, @y + 8, color, aim_x, aim_y, color)
      @parts[:aim].draw_rot(aim_x, aim_y, 3, 0, 0.5, 0.5)

      # arms
      @parts[:arms].draw_rot(@x + mirror * 4, @y + 12, 3, @arms_angle - 90.0, 0.1, 0.5, 1, mirror)
      # / aiming
    else
      # body
      @parts[:body].draw_rot(@x, @y - @bounce, 2, 0, 0.5, 0.5, mirror, 1)

      # AABB
      draw_aabb
      
      # aiming
      # laser
      aim_x = @x + Gosu::offset_x(@arms_angle, @ray)
      aim_y = @y + 4 + Gosu::offset_y(@arms_angle, @ray)
      color = Gosu::Color::RED
      Gosu.draw_line(@x, @y + 4, color, aim_x, aim_y, color)
      @parts[:aim].draw_rot(aim_x, aim_y, 3, 0, 0.5, 0.5)
      
      # arms
      @parts[:arms].draw_rot(@x, @y + 8, 3, @arms_angle - 90.0, 0.1, 0.5, 1, mirror)
      # / aiming
      
      # feet
      @parts[:leg].draw_rot(@x - 2, @y + 6, 2, @walk_angle, 0.5, 0.1, mirror, 1)
      @parts[:leg].draw_rot(@x + 2, @y + 6, 2, -@walk_angle, 0.5, 0.1, mirror, 1)
    end
  end
end