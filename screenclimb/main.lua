function handle_input(key)
  if key == 'right' then
      paddle_speed = 4
    elseif key == 'left' then
      paddle_speed = -4
    elseif key == 'space' then
      paddle_speed = 0
      paddle_vel = {0, 0}
    end
end
  
function update_physics(dt)
  paddle_vel[1] = paddle_vel[1] + (paddle_speed * dt)

  detect_collision()

  x_pos_bottom = paddle_pos_bottom[1] + paddle_vel[1]

  if x_pos_bottom < min_coll_pt then x_pos_bottom = min_coll_pt end
  if x_pos_bottom > max_coll_pt then x_pos_bottom = max_coll_pt end

  paddle_pos_bottom[1] = x_pos_bottom

  y_pos_left = paddle_pos_bottom[1] + window_height - paddle_dim[2]
  paddle_pos_left[2] = y_pos_left

  y_pos_right = -1 * (paddle_pos_bottom[1] - (window_height * 2) + (paddle_dim[2] * 3))
  paddle_pos_right[2] = y_pos_right

  x_pos_top = -1 * (paddle_pos_bottom[1] + window_width - (paddle_dim[2] * 0))
  paddle_pos_top[1] = x_pos_top
end

function detect_collision()
  if (paddle_pos_bottom[1] <= min_coll_pt) then
    paddle_vel[1] = math.max((paddle_vel[1] * -1) / 2, min_coll_pt)
  end

  if (paddle_pos_bottom[1] >= max_coll_pt) then
    paddle_vel[1] = math.min((paddle_vel[1] * -1) / 2, max_coll_pt)
  end
end

function draw_stopper()
  love.graphics.rectangle("fill", window_width - stopper_dim[1], 0, stopper_dim[1], stopper_dim[2])
end

function draw_paddle()
  love.graphics.rectangle("fill", paddle_pos_bottom[1], paddle_pos_bottom[2], paddle_dim[1], paddle_dim[2])
  love.graphics.rectangle("fill", paddle_pos_left[1], paddle_pos_left[2], paddle_dim[2], paddle_dim[1])
  love.graphics.rectangle("fill", paddle_pos_right[1], paddle_pos_right[2], paddle_dim[2], paddle_dim[1])
  love.graphics.rectangle("fill", paddle_pos_top[1], paddle_pos_top[2], paddle_dim[1], paddle_dim[2])
end


-- SYSTEM
function love.load()
  -- playdate screen resolution
  window_width = 400
  window_height = 240

  stopper_dim = {20, 20}

  paddle_speed = 0
  paddle_vel = {0,0}
  paddle_dim = {200,20}
  paddle_pos_bottom = { -- bottom center
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
  paddle_pos_top = {
    0,
    0
  }

  -- left and rightmost points at which the paddle is considered colliding with the stopper
  min_coll_pt = 0 - (paddle_dim[1] * 3) + paddle_dim[2]
  max_coll_pt = window_width

  love.window.setMode(window_width, window_height)
end

function love.draw()
  draw_paddle()
  draw_stopper()
end

function love.update(dt)
  update_physics(dt)
end

function love.keypressed(key)
    handle_input(key)
end