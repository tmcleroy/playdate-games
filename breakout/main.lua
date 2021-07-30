function handle_input(key)
    if key == 'right' then
        paddle_speed = 10
     elseif key == 'left' then
        paddle_speed = -10
     end
  end
  
  function update_physics(dt)
    paddle_vel[1] = paddle_vel[1] + (paddle_speed * dt)
  
    detect_collision()
  
    x_pos = paddle_pos[1] + paddle_vel[1]
    if x_pos < 0 then x_pos = 0 end
    if x_pos > window_width - paddle_dim[1] then x_pos = window_width - paddle_dim[1] end
    paddle_pos[1] = x_pos
  end
  
  function detect_collision()
    if (paddle_pos[1] <= 0) then
      -- paddle_pos[1] = 0
      paddle_vel[1] = math.max((paddle_vel[1] * -1) / 2, 0)
    end
  
    if (paddle_pos[1] >= window_width - paddle_dim[1]) then
      -- paddle_pos[1] = window_width - paddle_dim[1]
      paddle_vel[1] = math.min((paddle_vel[1] * -1) / 2, window_width - paddle_dim[1])
    end
  end
  
  function draw_paddle()
    love.graphics.rectangle("line", paddle_pos[1], paddle_pos[2], paddle_dim[1], paddle_dim[2])
  end
  
  
  -- SYSTEM
  function love.load()
    -- playdate screen resolution
    window_width = 400
    window_height = 240
  
    paddle_speed = 0
    paddle_vel = {0,0}
    paddle_dim = {100,20}
    paddle_pos = { -- centered
      (window_width / 2) - (paddle_dim[1] / 2),
      window_height - paddle_dim[2]
    }
  
    love.window.setMode(window_width, window_height)
  end
  
  function love.draw()
    draw_paddle()
  end
  
  function love.update(dt)
    update_physics(dt)
  end
  
  function love.keypressed(key)
     handle_input(key)
  end