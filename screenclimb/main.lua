function init_game()
  -- playdate screen resolution
  window_width = 400
  window_height = 240

  score = 0

  use_crank = true
  crank_angle = 0
  crank_step_amount = 3
  -- crank_step_amount = 1
  crank_paddle_vel = 0
  prev_crank_angle = 0

  ball_dim = {20,20}
  ball_angle = 0
  ball_angle_vel = 0
  ball_vel_initial = {0,0}
  ball_pos_initial = {(window_width / 2) - (ball_dim[1] / 2), (window_height / 2) - (ball_dim[2] / 2)} -- center
  ball_pos = ball_pos_initial
  ball_vel = ball_vel_initial
  ball_vel_max = 5
  ball_rotation_speed = 0.1
  ball_paddle_vel_transfer = 0.33 -- percentage of paddle velocity to transfer to ball on collision
  ball_paddle_rotation_transfer = 0.1 -- amount of paddle velocity to transfer to ball rotation on collision
  colliding_paddles = {} -- track previous frame collisions so ball can be reset when it's stuck

  paddle_speed = 0
  paddle_vel = {0,0}
  paddle_vel_max = 10
  paddle_decrease_amount = 10
  paddle_decreases = 0
  original_paddle_width = 200
  paddle_width = original_paddle_width
  paddle_height = 20
  paddle_dim = {
    bottom = {paddle_width,paddle_height},
    left = {paddle_height,paddle_width},
    right = {paddle_height,paddle_width},
    top = {paddle_width,paddle_height}
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
end


-- INPUT

function handle_continuous_input()
  if love.keyboard.isDown('a') then
    ball_angle = ball_angle - ball_rotation_speed
  end
  if love.keyboard.isDown('d') then
    ball_angle = ball_angle + ball_rotation_speed
  end

  if love.keyboard.isDown('right') then
    paddle_speed = 4
    crank_angle = crank_angle + crank_step_amount
    if (crank_angle >= 360) then crank_angle = 0 end
    crank_paddle_vel = crank_angle - prev_crank_angle
  elseif love.keyboard.isDown('left') then
    paddle_speed = -4
    crank_angle = crank_angle - crank_step_amount
    if (crank_angle <= -1) then crank_angle = 359 end
    crank_paddle_vel = crank_angle - prev_crank_angle
  else
    crank_paddle_vel = 0
  end

  prev_crank_angle = crank_angle
end

function handle_input(key)
  if key == 'space' then
    paddle_speed = 0
    paddle_vel = {0, 0}
    ball_vel = {0, 0}
  elseif key == 'return' then
    ball_vel = use_crank and {2, 0} or {0, 2}
  elseif key == 'r' then
    init_game()
  elseif key == "escape" then
    love.event.quit()
  end
end


-- PHYSICS

function update_physics(dt)
  -- ball
  adjust_ball_velocity(dt)
  ball_pos = {ball_pos[1] + ball_vel[1], ball_pos[2] + ball_vel[2]}
  ball_angle = ball_angle + ball_angle_vel

  -- paddle
  adjust_paddle_velocity(dt)

  local bottom_pos = use_crank
    and -- bottom_pos should range from -800 to 1200, convert the angle value to a number in that range
                                          -- move the paddle so it stays centered when its width decreases
      -800 + ((crank_angle / 359) * 1200) + (paddle_decreases * (paddle_decrease_amount / 2))
    or
      paddle_pos.bottom[1] + paddle_vel[1]

  local paddle_diff = (paddle_width - (window_width / 2))
  local left_pos = paddle_pos.bottom[1] + (window_height - paddle_height)
  local right_pos = (window_width + paddle_height - paddle_diff ) - bottom_pos
  local top_pos = (bottom_pos >= -(window_width + paddle_diff) and -1 or 1) * math.abs(bottom_pos + (window_width + paddle_diff))

  if (bottom_pos <= -580) then
    right_pos = -200 - paddle_diff + math.abs(bottom_pos + 580)
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
  local collide_top = ball_pos[2] <= 0
  local collide_bottom = ball_pos[2] >= window_height - ball_dim[2]
  local collide_left = ball_pos[1] <= 0
  local collide_right = ball_pos[1] >= window_width - ball_dim[1]
  local collided_with_wall = collide_top or collide_bottom or collide_left or collide_right
  local small_rand_range = math.random(-10, 10) / 60

  if collided_with_wall then
    init_game()
    return
  end

  if (collide_top or collide_bottom) then
    ball_vel[2] = ball_vel[2] * -1 + small_rand_range
    ball_vel[1] = ball_vel[1] + small_rand_range
  end
  if (collide_left or collide_right) then
    ball_vel[1] = ball_vel[1] * -1  + small_rand_range
    ball_vel[2] = ball_vel[2] + small_rand_range
  end

  -- paddle collision, only check collisions with visible paddles
  for k, v in pairs(visible_paddles) do
    if (visible_paddles[k]) then
      local colliding_with_paddle = colliding(
        ball_pos[1], ball_pos[2], ball_dim[1], ball_dim[2],
        paddle_pos[k][1], paddle_pos[k][2], paddle_dim[k][1], paddle_dim[k][2]
      )

      if colliding_with_paddle then
        if (k == "bottom") then
          --                               increase ball vel with each paddle hit
          ball_vel[2] = -1 * ball_vel[2] - math.abs(small_rand_range * 1.5)
          ball_vel[1] = ball_vel[1] + (crank_paddle_vel / math.random(crank_step_amount - 0.25, crank_step_amount + 0.25)) + small_rand_range
        end
        if (k == "top") then
          ball_vel[2] = -1 * ball_vel[2] + math.abs(small_rand_range * 1.5)
          ball_vel[1] = ball_vel[1] - (crank_paddle_vel / math.random(crank_step_amount - 0.25, crank_step_amount + 0.25)) + small_rand_range
        end
        if (k == "left") then
          ball_vel[1] = -1 * ball_vel[1] + math.abs(small_rand_range * 1.5)
          ball_vel[2] = ball_vel[2] + (crank_paddle_vel / math.random(crank_step_amount - 0.25, crank_step_amount + 0.25)) + small_rand_range
        end
        if (k == "right") then
          ball_vel[1] = -1 * ball_vel[1] - math.abs(small_rand_range * 1.5)
          ball_vel[2] = ball_vel[2] - (crank_paddle_vel / math.random(crank_step_amount - 0.25, crank_step_amount + 0.25)) + small_rand_range
        end

        -- transfer paddle velocity into ball rotation
        ball_angle_vel = ball_angle_vel + (crank_paddle_vel / crank_step_amount) * small_rand_range * ball_paddle_rotation_transfer
        -- collided last frame, indicates a stuck ball, reset game
        if (colliding_paddles[k]) then
          ball_pos = ball_pos_initial
          ball_vel = ball_vel_initial
          init_game()
          return
        end

        if (paddle_width == paddle_height) then
          init_game()
        else
          paddle_width = math.max(paddle_width - paddle_decrease_amount, paddle_height)
          paddle_decreases = paddle_decreases + 1
          score = score + 1
        end
        adjust_paddle_size()
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
  local new_paddle_vel = paddle_vel[1] + (paddle_speed * dt)
  
  -- limit paddle velocity to max
  if (new_paddle_vel < 0) then
    new_paddle_vel = math.max(-1 * paddle_vel_max, new_paddle_vel)
  elseif (new_paddle_vel > 0) then
    new_paddle_vel = math.min(paddle_vel_max, new_paddle_vel)
  end

  paddle_vel[1] = new_paddle_vel
end

function adjust_paddle_size()
  paddle_dim = {
    bottom = {paddle_width,paddle_height},
    left = {paddle_height,paddle_width},
    right = {paddle_height,paddle_width},
    top = {paddle_width,paddle_height}
  }
end

function get_visible_paddles()
  local bottom =
    paddle_pos.bottom[1] <= 380 and paddle_pos.bottom[1] >= -(paddle_width - paddle_height)
  local left =
    paddle_pos.left[2] <= 220 and paddle_pos.left[2] >= -(paddle_width - paddle_height)
  local right =
  paddle_pos.right[2] <= 220 and paddle_pos.right[2] >= -(paddle_width - paddle_height)
  local top =
    paddle_pos.top[1] <= 380 and paddle_pos.top[1] >= - (paddle_width - paddle_height)

  return { bottom = bottom, left = left, right = right, top = top }
  -- return { bottom = true, left = true, right = true, top = true }
end


-- DRAWING

function draw_ball()
  drawRotatedRectangle("fill", ball_pos[1] + (ball_dim[1] / 2), ball_pos[2] + (ball_dim[2] / 2), ball_dim[1], ball_dim[2], ball_angle)
end

function draw_paddles()
  for k, v in pairs(visible_paddles) do
    if visible_paddles[k] then
      love.graphics.rectangle("fill", paddle_pos[k][1], paddle_pos[k][2], paddle_dim[k][1], paddle_dim[k][2], paddle_border_radius)
    end
  end
end

function draw_score()
  love.graphics.print(score, 5, 2)
end


-- SYSTEM

function love.load()
  init_game()
  love.graphics.setFont(love.graphics.newFont(18))
  love.keyboard.setKeyRepeat(true)
  love.window.setMode(window_width, window_height)
end

function love.draw()
  draw_paddles()
  draw_ball()
  draw_score()
end

function love.update(dt)
  handle_continuous_input()
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