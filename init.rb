require 'gosu'
require_relative './utils.rb'
require_relative './map.rb'
require_relative './camera.rb'
require_relative './hero.rb'
require_relative './projectile.rb'
require_relative './enemy.rb'

class Window < Gosu::Window
  attr_reader :map
  def initialize
    super(640, 480, true)
    @tile_size = 32
    @current_level = 0
    next_level
    @font = Gosu::Font.new(24)
    @overlay = Gosu::Image.new('./gfx/overlay.png', retro: true)

    @music = Gosu::Song.new('./sfx/Juhani Junkala [Retro Game Music Pack] Level 3.wav')
    @music.volume = 0.2
    @music.play(true)
  end

  def button_down(id)
    super
    close! if id == Gosu::KB_ESCAPE

    case @state
    when :game
      @hero.button_down(id)
    when :victory, :game_over
      @current_level = 0
      next_level
    end
  end

  def needs_cursor?; false; end

  def next_level
    @state = :game
    @current_level += 1
    filename = "./levels/level_#{@current_level}.png"
    if File.exist?(filename)
      @map = Map.new(self, filename, @tile_size)
      spawn_point = @map.spawn_point
      @hero = Hero.new(self, spawn_point[0], spawn_point[1])
      @camera = Camera.new(self)
      @camera.set_target(@hero)
    else
      @state = :victory
    end
  end

  def warp_mouse
    self.mouse_x = 0 if self.mouse_x < 0
    self.mouse_y = 0 if self.mouse_y < 0
    self.mouse_x = self.width if self.mouse_x > self.width
    self.mouse_y = self.height if self.mouse_y > self.height
  end

  def update
    warp_mouse
    @time ||= Gosu::milliseconds
    @delta = Gosu::milliseconds - @time

    case @state
    when :game
      @hero.update(@delta, self.mouse_x, self.mouse_y)
      @camera.update(@delta)
      @map.update(@delta, @hero)

      @state = :game_over if @hero.lives <= 0

      if @map.hero_on_goal(@hero)
        next_level
      end
    end

    @time = Gosu::milliseconds
  end

  def draw_hud
    @overlay.draw(0, 0, 9)
    @font.draw_text("Level #{@current_level}", 10, 10, 10)
    @font.draw_text("#{@hero.lives} Lives", 10, 20 + @font.height - 10, 10)
    text = "#{@map.enemies.size} Enemies Left"
    @font.draw_text(text, self.width - @font.text_width(text), 10, 10)
  end

  def draw
    case @state
    when :game
      @camera.look do
        @map.draw
        @hero.draw
        @hero.projectiles.each {|projectile| projectile.draw}
      end
      draw_hud
    when :victory
      @camera.look do
        @map.draw
        @hero.draw
      end
      @font.draw_text('Congratulations ! You cleaned every area !', 100, 150, 0)
      @font.draw_text('            - Press any key to restart -', 100, 180, 0)
      draw_hud
    when :game_over
      @camera.look do
        @map.draw
        @hero.draw
      end
      @font.draw_text('Game Over. Try again !', 100, 150, 0)
      @font.draw_text('            - Press any key to restart -', 100, 180, 0)
      draw_hud
    end
  end
end

Window.new.show