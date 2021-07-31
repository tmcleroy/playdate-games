function handle_input(key)
  if key == 'right' then
      paddle_speed = 4
    elseif key == 'left' then
      paddle_speed = -4
    elseif key == 'space' then
      paddle_speed = 0
      paddle_vel = {0, 0}
      ball_vel = {0, 0}
    elseif key == 'return' then
      ball_vel = {1, 2}
    end
end
  
function update_physics(dt)
  -- ball
  adjust_ball_velocity()

  ball_vel[1] = ball_vel[1] + (ball_speed * dt)
  ball_vel[2] = ball_vel[2] + (ball_speed * dt)

  ball_pos[1] = ball_pos[1] + ball_vel[1]
  ball_pos[2] = ball_pos[2] + ball_vel[2]
  -- paddle
  paddle_vel[1] = paddle_vel[1] + (paddle_speed * dt)

  adjust_paddle_velocity()

  x_pos_bottom = paddle_pos.bottom[1] + paddle_vel[1]

  if x_pos_bottom < min_coll_pt then x_pos_bottom = min_coll_pt end
  if x_pos_bottom > max_coll_pt then x_pos_bottom = max_coll_pt end

  paddle_pos.bottom[1] = x_pos_bottom

  y_pos_left = paddle_pos.bottom[1] + window_height - paddle_dim[2]
  paddle_pos.left[2] = y_pos_left

  y_pos_right = -1 * (paddle_pos.bottom[1] - (window_height * 2) + (paddle_dim[2] * 3))
  paddle_pos.right[2] = y_pos_right

  x_pos_top = -1 * (paddle_pos.bottom[1] + window_width - (paddle_dim[2] * 0))
  paddle_pos.top[1] = x_pos_top
end

function adjust_ball_velocity()
  -- floor                                          cieling
  if (ball_pos[2] >= window_height - ball_dim[2] or ball_pos[2] <= 0) then
    ball_vel[2] = ball_vel[2] * -1
  end
  -- left wall            -- right wall
  if (ball_pos[1] <= 0 or ball_pos[1] >= window_width - ball_dim[1]) then
    ball_vel[1] = ball_vel[1] * -1
  end

  for k, v in pairs(visible_paddles) do
    if (visible_paddles[k]) then
      colliding_with_paddle = colliding(
        ball_pos[1], ball_pos[2], ball_dim[1], ball_dim[2],
        paddle_pos[k][1], paddle_pos[k][2], paddle_dim[1], paddle_dim[2]
      )

      if colliding_with_paddle then
        if (k == "right" or k == "left") then
          ball_vel[1] = ball_vel[1] * -1
        end
        if (k == "top" or k == "bottom") then
          ball_vel[2] = ball_vel[2] * -1
        end
      end

      -- -- TODO adjust ball velocity based on collision
      -- print("colliding with " .. k)
      -- print(colliding_with_paddle)
      -- print "!!!!!!!!!!"
    end
  end
end

function adjust_paddle_velocity()
  if (paddle_pos.bottom[1] <= min_coll_pt) then
    paddle_vel[1] = math.max((paddle_vel[1] * -1) / 2, min_coll_pt)
  end

  if (paddle_pos.bottom[1] >= max_coll_pt) then
    paddle_vel[1] = math.min((paddle_vel[1] * -1) / 2, max_coll_pt)
  end
end

function draw_ball()
  love.graphics.rectangle("fill", ball_pos[1], ball_pos[2], ball_dim[1], ball_dim[2])
end

function draw_stopper()
  love.graphics.rectangle("fill", stopper_pos[1], stopper_pos[2], stopper_dim[1], stopper_dim[2])
end

function draw_paddle()
  if visible_paddles.bottom then
    love.graphics.rectangle("fill", paddle_pos.bottom[1], paddle_pos.bottom[2], paddle_dim[1], paddle_dim[2], paddle_border_radius)
  end
  if visible_paddles.left then
    love.graphics.rectangle("fill", paddle_pos.left[1], paddle_pos.left[2], paddle_dim[2], paddle_dim[1], paddle_border_radius)
  end
  if visible_paddles.right then
    love.graphics.rectangle("fill", paddle_pos.right[1], paddle_pos.right[2], paddle_dim[2], paddle_dim[1], paddle_border_radius)
  end
  if visible_paddles.top then
    love.graphics.rectangle("fill", paddle_pos.top[1], paddle_pos.top[2], paddle_dim[1], paddle_dim[2], paddle_border_radius)
  end
end

function get_visible_paddles()
  bottom =
    paddle_pos.bottom[1] <= window_width - paddle_dim[2] and
    paddle_pos.bottom[1] >= -1 * (paddle_dim[1] - paddle_dim[2])
  left =
    paddle_pos.left[2] <= window_height - paddle_dim[2] and
    paddle_pos.left[2] >= -1 * (window_height - (paddle_dim[2] * 3))
  right =
    paddle_pos.right[2] <= window_height - paddle_dim[2]
  top =
    paddle_pos.top[1] >= -1 * (paddle_dim[1] - paddle_dim[2])

  return { bottom = bottom, left = left, right = right, top = top }
end


-- SYSTEM
function love.load()
  -- playdate screen resolution
  window_width = 400
  window_height = 240

  stopper_dim = {20, 20}
  stopper_pos = {window_width - stopper_dim[1], 0} -- top right

  ball_dim = {20, 20}
  ball_pos = {(window_width / 2) - (ball_dim[1] / 2), (window_height / 2) - (ball_dim[2] / 2)} -- center
  ball_vel = {0, 0}
  ball_speed = 0

  paddle_speed = 0
  paddle_vel = {0,0}
  paddle_dim = {200,20}
  paddle_border_radius = paddle_dim[2] / 2 -- set to 0 to square it off
  paddle_pos = {
    bottom = { -- bottom center
      (window_width / 2) - (paddle_dim[1] / 2),
      window_height - paddle_dim[2]
    },
    left = {
      0,
      window_height - paddle_dim[1]
    },
    right = {
      window_width - paddle_dim[2],
      0
    },
    top = {
      0,
      0
    }
  }

  -- left and rightmost points at which the paddle is considered colliding with the stopper
  min_coll_pt = 0 - (paddle_dim[1] * 3) + paddle_dim[2]
  max_coll_pt = window_width

  love.window.setMode(window_width, window_height)
end

function love.draw()
  draw_paddle()
  draw_stopper()
  draw_ball()
end

function love.update(dt)
  visible_paddles = get_visible_paddles()
  update_physics(dt)
end

function love.keypressed(key)
  handle_input(key)
end


-- UTIL

-- https://love2d.org/forums/viewtopic.php?p=196465&sid=7893979c5233b13efed2f638e114ce87#p196465
function colliding(x1,y1,w1,h1, x2,y2,w2,h2)
  return (
    x1 < x2+w2 and
    x2 < x1+w1 and
    y1 < y2+h2 and
    y2 < y1+h1
  )
end

-- https://www.codegrepper.com/code-examples/lua/lua+object+to+string
function object_to_string(o)
  if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
              if type(k) ~= 'number' then k = '"'..k..'"' end
              s = s .. '['..k..'] = ' .. object_to_string(v) .. ','
      end
      return s .. '} '
  else
      return tostring(o)
  end
end