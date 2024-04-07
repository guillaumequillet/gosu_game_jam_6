class Camera
  def initialize(window)
    @window = window
    @target_x, @target_y = 0, 0
  end

  def set_target(target)
    @target = target
  end

  def update(delta)
    @target_x, @target_y = @target.x, @target.y
  end

  def look
    Gosu.translate(@window.width / 2 - @target_x, @window.height / 2 - 400) do
      yield
    end
  end
end