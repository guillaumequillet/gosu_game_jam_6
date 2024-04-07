class Map
  attr_reader :spawn_point, :goal_point, :enemies, :min, :max
  def initialize(window, filename, tile_size)
    @window = window
    @filename = filename

    @tile_size = tile_size
    @colors = {
      empty: Gosu::Color.new(255, 255, 0, 255),
      solid: Gosu::Color::WHITE,
      spawn: Gosu::Color::BLUE,
      goal: Gosu::Color::GREEN,
      boss: Gosu::Color::BLACK,
      enemy_soldier: Gosu::Color::RED,
      enemy_soldier2: Gosu::Color.new(255, 178, 0, 255)
    }

    @sfx = {
      goal: Gosu::Sample.new('./sfx/message-incoming-2-199577.mp3')
    }

    @minimap = Gosu::Image.new(@filename, retro: true)
    @tileset = Gosu::Image.load_tiles('./gfx/tileset.png', @tile_size, @tile_size, retro: true)
    load_map
  end

  def load_map
    @min = 0
    @max = @minimap.width * @tile_size
    @solid_tiles = []
    @spawn_point = nil
    @enemies = []
    @exit_discovered = false

    @minimap.height.times do |y|
      @minimap.width.times do |x|
        color = @minimap.get_pixel(x, y)
        case color
        when @colors[:solid]
          @solid_tiles.push [x, y]
        when @colors[:enemy_soldier]
          add_enemy(:soldier, (x + 0.5) * @tile_size, (y + 0.5) * @tile_size)
        when @colors[:enemy_soldier2]
          add_enemy(:soldier2, (x + 0.5) * @tile_size, (y + 0.5) * @tile_size)
        when @colors[:boss]
          add_enemy(:boss, (x + 0.5) * @tile_size, (y + 0.5) * @tile_size)
        when @colors[:spawn]
          @spawn_point = [(x + 0.5) * @tile_size, (y + 0.5) * @tile_size]
        when @colors[:goal]
          @goal_point = [x * @tile_size, y * @tile_size]
        end
      end
    end
  end

  def add_enemy(type, x, y)
    case type
    when :soldier
      @enemies.push Soldier.new(@window, x, y)
    when :soldier2
      @enemies.push Soldier2.new(@window, x, y)
    when :boss
      @enemies.push Boss.new(@window, x, y)
    end
  end

  def update(delta, hero)
    @enemies.each {|enemy| enemy.update(delta, hero)}

    @enemies.delete_if {|enemy| enemy.to_delete}

    if @enemies.empty? && !@exit_discovered
      @sfx[:goal].play
      @exit_discovered = true
    end
  end

  def hero_on_goal(hero)
    return false if hero.aabb_x + hero.aabb_w < @goal_point[0]
    return false if hero.aabb_x > @goal_point[0] + @tile_size
    return false if hero.aabb_y + hero.aabb_h < @goal_point[1]
    return false if hero.aabb_y > @goal_point[1] + @tile_size

    return true if @enemies.empty?
  end

  def draw
    # map drawing
    @solid_tiles.each do |solid_tile|
      x, y = solid_tile
      tile = 3 # defaut top
      tile = 2 if @solid_tiles.include?([x, y - 1]) # no border if top started before

      tile = 0 if y == 14 # bottom line


      @tileset[tile].draw(x * @tile_size, y * @tile_size, 0)
    end
    
    if @exit_discovered
      @tileset[1].draw(@goal_point[0], @goal_point[1], 0)
    end

    @enemies.each {|enemy| enemy.draw}
  end
end