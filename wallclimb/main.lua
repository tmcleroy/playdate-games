function handle_input(key)
  if key == 'right' then
      paddle_speed = 10
    elseif key == 'left' then
      paddle_speed = -10
    elseif key == 'space' then
      paddle_speed = 0
      paddle_vel = {0, 0}
    end
end
  
function update_physics(dt)
  paddle_vel[1] = paddle_vel[1] + (paddle_speed * dt)

  detect_collision()

  x_pos = paddle_pos_bottom[1] + paddle_vel[1]
  if x_pos < 0 - paddle_dim[1] - 1 then x_pos = 0 - paddle_dim[1] - 1 end
  if x_pos > window_width then x_pos = window_width end
  paddle_pos_bottom[1] = x_pos

  y_pos_left = paddle_pos_bottom[1] + window_height
  paddle_pos_left[2] = y_pos_left

  y_pos_right = -1 * (paddle_pos_bottom[1] - (window_height * 2) + (paddle_dim[2] * 2))
  paddle_pos_right[2] = y_pos_right
end

function detect_collision()
  if (paddle_pos_bottom[1] <= 0 - paddle_dim[1] - 1) then
    paddle_vel[1] = math.max((paddle_vel[1] * -1) / 2, 0 - paddle_dim[1] - 1)
  end

  if (paddle_pos_bottom[1] >= window_width) then
    paddle_vel[1] = math.min((paddle_vel[1] * -1) / 2, window_width)
  end
end

function draw_paddle()
  love.graphics.rectangle("fill", paddle_pos_bottom[1], paddle_pos_bottom[2], paddle_dim[1], paddle_dim[2])
  love.graphics.rectangle("fill", paddle_pos_left[1], paddle_pos_left[2], paddle_dim[2], paddle_dim[1])
  love.graphics.rectangle("fill", paddle_pos_right[1], paddle_pos_right[2], paddle_dim[2], paddle_dim[1])
end


-- SYSTEM
function love.load()
  -- playdate screen resolution
  window_width = 400
  window_height = 240

  paddle_speed = 0
  paddle_vel = {0,0}
  paddle_dim = {200,20}
  paddle_pos_bottom = {
    (window_width / 2) - (paddle_dim[1] / 2),
    window_height - paddle_dim[2]
  }
  paddle_pos_left = {
    0,
    window_height - paddle_dim[1]
  }
  paddle_pos_right = {
    window_width - paddle_dim[2],
    0
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