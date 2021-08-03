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
      ball_vel = {0, 2}
    elseif key == 'a' then
      ball_angle = ball_angle - ball_rotation_speed
    elseif key == 'd' then
      ball_angle = ball_angle + ball_rotation_speed
    elseif key == "escape" then
      love.event.quit()
    end
end
  
function update_physics(dt)
  -- ball
  adjust_ball_velocity(dt)
  ball_pos = {ball_pos[1] + ball_vel[1], ball_pos[2] + ball_vel[2]}

  -- paddle
  adjust_paddle_velocity(dt)

  bottom_pos = paddle_pos.bottom[1] + paddle_vel[1]
  left_pos = paddle_pos.bottom[1] + 220
  right_pos = 420 - bottom_pos
  top_pos = (bottom_pos >= -400 and -1 or 1) * math.abs(bottom_pos + 400)

  -- when near the end of paddle cycle, position the right paddle to make the transition appear seamless
  if (bottom_pos <= -580) then
    right_pos = -200 + math.abs(bottom_pos + 580)
  end
  -- seamless reset of bottom paddle position that controls all other paddle positions
  if (bottom_pos <= -800) then
    bottom_pos = 400
  elseif (bottom_pos >= 400) then
    bottom_pos = -800
  end

  paddle_pos.bottom[1] = bottom_pos
  paddle_pos.left[2] = left_pos
  paddle_pos.right[2] = right_pos
  paddle_pos.top[1] = top_pos
end

function adjust_ball_velocity()
  -- wall collision
  collide_top = ball_pos[2] <= 0
  collide_bottom = ball_pos[2] >= window_height - ball_dim[2]
  collide_left = ball_pos[1] <= 0
  collide_right = ball_pos[1] >= window_width - ball_dim[1]

  if (collide_top or collide_bottom) then
    ball_vel[2] = ball_vel[2] * -1
  end
  if (collide_left or collide_right) then
    ball_vel[1] = ball_vel[1] * -1
  end

  -- paddle collision, only check collisions with visible paddles
  for k, v in pairs(visible_paddles) do
    if (visible_paddles[k]) then
      colliding_with_paddle = colliding(
        ball_pos[1], ball_pos[2], ball_dim[1], ball_dim[2],
        paddle_pos[k][1], paddle_pos[k][2], paddle_dim[k][1], paddle_dim[k][2]
      )

      if colliding_with_paddle then
        if (k == "bottom") then
          ball_vel[2] = -1 * ball_vel[2]
          ball_vel[1] = ball_vel[1] + (paddle_vel[1] * ball_paddle_vel_transfer)
        end
        if (k == "top") then
          ball_vel[2] = -1 * ball_vel[2]
          ball_vel[1] = ball_vel[1] + (paddle_vel[1] * ball_paddle_vel_transfer * -1)
        end
        if (k == "left") then
          ball_vel[1] = -1 * ball_vel[1]
          ball_vel[2] = ball_vel[2] + (paddle_vel[1] * ball_paddle_vel_transfer)
        end
        if (k == "right") then
          ball_vel[1] = -1 * ball_vel[1]
          ball_vel[2] = ball_vel[2] + (paddle_vel[1] * ball_paddle_vel_transfer * -1)
        end
        -- collided last frame, indicates a stuck ball, reset ball
        if (colliding_paddles[k]) then
          ball_pos = ball_pos_initial
          ball_vel = ball_vel_initial
        end
      end

      colliding_paddles[k] = colliding_with_paddle
    end
  end

  -- limit to max vel
  if (ball_vel[1] < -1 * ball_vel_max) then
    ball_vel[1] = -1 * ball_vel_max
  end
  if (ball_vel[1] > ball_vel_max) then
    ball_vel[1] = ball_vel_max
  end
  if (ball_vel[2] < -1 * ball_vel_max) then
    ball_vel[2] = -1 * ball_vel_max
  end
  if (ball_vel[2] > ball_vel_max) then
    ball_vel[2] = ball_vel_max
  end
end

function adjust_paddle_velocity(dt)
  new_paddle_vel = paddle_vel[1] + (paddle_speed * dt)
  
  -- limit paddle velocity to max
  if (new_paddle_vel < 0) then
    new_paddle_vel = math.max(-1 * paddle_vel_max, new_paddle_vel)
  elseif (new_paddle_vel > 0) then
    new_paddle_vel = math.min(paddle_vel_max, new_paddle_vel)
  end

  paddle_vel[1] = new_paddle_vel
end

function draw_ball()
  -- love.graphics.rectangle("fill", ball_pos[1], ball_pos[2], ball_dim[1], ball_dim[2])
  drawRotatedRectangle("fill", ball_pos[1] + (ball_dim[1] / 2), ball_pos[2] + (ball_dim[2] / 2), ball_dim[1], ball_dim[2], ball_angle)
end

function draw_paddles()
  for k, v in pairs(visible_paddles) do
    if visible_paddles[k] then
      love.graphics.rectangle("fill", paddle_pos[k][1], paddle_pos[k][2], paddle_dim[k][1], paddle_dim[k][2], paddle_border_radius)
    end
  end
end

-- problem in top right corner
function get_visible_paddles()
  bottom =
    paddle_pos.bottom[1] <= window_width - paddle_dim.bottom[2] and
    paddle_pos.bottom[1] >= -1 * (paddle_dim.bottom[1] - paddle_dim.bottom[2])
  left =
    paddle_pos.left[2] <= window_height - paddle_dim.left[1] and
    paddle_pos.left[2] >= -1 * (window_height - (paddle_dim.left[1] * 3))
  right =
    paddle_pos.right[2] <= window_height - paddle_dim.right[1]
  top =
    paddle_pos.top[1] >= -1 * (paddle_dim.top[1] - paddle_dim.top[2])

  return { bottom = bottom, left = left, right = right, top = top }
  -- return { bottom = true, left = true, right = true, top = true }
end


-- SYSTEM
function love.load()
  -- playdate screen resolution
  window_width = 400
  window_height = 240

  love.keyboard.setKeyRepeat(true, 0)

  stopper_dim = {20,20}
  stopper_pos = {window_width - stopper_dim[1],0} -- top right

  ball_dim = {20,20}
  ball_angle = 0
  ball_vel_initial = {0,0}
  ball_pos_initial = {(window_width / 2) - (ball_dim[1] / 2), (window_height / 2) - (ball_dim[2] / 2)} -- center
  ball_pos = ball_pos_initial
  ball_vel = ball_vel_initial
  ball_vel_max = 5
  ball_rotation_speed = 0.1
  ball_paddle_vel_transfer = 0.33 -- percentage of paddle velocity to transfer to ball on collision
  colliding_paddles = {} -- track previous frame collisions so ball can be reset when it's stuck

  paddle_speed = 0
  paddle_vel = {0,0}
  paddle_vel_max = 10
  paddle_dim = {
    bottom = {200,20},
    left = {20,200},
    right = {20,200},
    top = {200,20}
  }
  paddle_border_radius = paddle_dim.bottom[2] / 2 -- set to 0 to square it off
  paddle_pos = {
    bottom = { -- bottom center
      (window_width / 2) - (paddle_dim.bottom[1] / 2),
      window_height - paddle_dim.bottom[2]
    },
    left = {
      0,
      window_height - paddle_dim.left[2]
    },
    right = {
      window_width - paddle_dim.right[1],
      0
    },
    top = {
      0,
      0
    }
  }

  -- left and rightmost points at which the paddle is considered colliding with the stopper
  min_coll_pt = -1 * (window_width + window_height - (paddle_dim.bottom[2] * 3))
  max_coll_pt = window_width

  love.window.setMode(window_width, window_height)
end

function love.draw()
  draw_paddles()
  draw_ball()
end

function love.update(dt)
  visible_paddles = get_visible_paddles()
  print(object_to_string(visible_paddles))
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

-- https://love2d.org/wiki/love.graphics.rectangle
-- modified to rotate about the center of the rectangle
function drawRotatedRectangle(mode, x, y, width, height, angle)
	-- We cannot rotate the rectangle directly, but we
	-- can move and rotate the coordinate system.
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.rotate(angle)
	love.graphics.rectangle(mode, -1*(width/2), -1*(height/2), width, height)
	love.graphics.pop()
end