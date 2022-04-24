import "CoreLibs/graphics"
import "util"

local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

-- INIT

function init_game()
  init_sounds()
  init_sprites()
  
  frame_rate = 50

  playdate.display.setRefreshRate(frame_rate)
  
  -- window
  window_dim = {400, 240} -- playdate screen resolution

  -- feature vals
  speed_mult = 70 -- value to multiply dt by for consistent game speed across devices

  -- score
  score = 0

  -- crank
  crank_step_amount = 6
  crank_angle = 0
  crank_paddle_vel = 0 -- used to calculate paddle velocity for transfering to rotation of ball

  -- ball
  ball_dim = {20,20}
  ball_vel_initial = {0,0}
  ball_pos_initial = {(window_dim[1] / 2) - (ball_dim[1] / 2), (window_dim[2] / 2) - (ball_dim[2] / 2)} -- center of screen
  ball_pos = ball_pos_initial
  ball_vel = ball_vel_initial
  ball_vel_max = 3

end

function init_sprites()
  ball_img = gfx.image.new('img/ball.png')
  white_img = gfx.image.new('img/white.png')
end

function init_sounds()
end

-- INPUT

function handle_input()
  -- if playdate.buttonIsPressed(playdate.kButtonDown) then
  --   ball_vel[2] = 2
  -- end
  if playdate.buttonIsPressed(playdate.kButtonUp) then
    ball_vel[2] = -2
  end
  -- if playdate.buttonIsPressed(playdate.kButtonRight) then
  --   ball_vel[1] = 2
  -- end
  -- if playdate.buttonIsPressed(playdate.kButtonLeft) then
  --   ball_vel[1] = -2
  -- end

  crank_angle = playdate.getCrankPosition()
  crank_paddle_vel = playdate.getCrankChange()
end

-- PHYSICS

function update_physics(dt)
  -- ball
  handle_collisions(dt)
  x_pos = ball_pos[1] + ball_vel[1] * dt * speed_mult
  y_pos = ball_pos[2] + ball_vel[2] * dt * speed_mult
  rad = math.rad(crank_angle - 90) -- convert crank_angle to radians
  x_vec = math.cos(rad)
  y_vec = math.sin(rad)
  ball_pos = {x_pos + x_vec, y_pos + y_vec}
end

function handle_collisions()
  -- wall collision
  local collide_top = ball_pos[2] <= 0
  local collide_bottom = ball_pos[2] >= window_dim[2] - ball_dim[2]
  local collide_left = ball_pos[1] <= 0
  local collide_right = ball_pos[1] >= window_dim[1] - ball_dim[1]
  local collided_with_wall = collide_top or collide_bottom or collide_left or collide_right


  if (collide_top or collide_bottom) then
    ball_vel[2] = ball_vel[2] * -1
    ball_vel[1] = ball_vel[1]
  end
  if (collide_left or collide_right) then
    ball_vel[1] = ball_vel[1] * -1
    ball_vel[2] = ball_vel[2]
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

-- DRAWING

function draw_ball()
  if prev_x and prev_y and prev_crank_angle then
    -- white_img.drawRotated(white_img, prev_x, prev_y, prev_crank_angle)
  end
  ball_img.drawRotated(ball_img, ball_pos[1] + (ball_dim[1] / 2), ball_pos[2] + (ball_dim[2] / 2), crank_angle)
  prev_x = ball_pos[1] + (ball_dim[1] / 2)
  prev_y = ball_pos[2] + (ball_dim[2] / 2)
  prev_crank_angle = crank_angle

end

function draw_background()
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(0, 0, window_dim[1], window_dim[2])
  gfx.setBackgroundColor(gfx.kColorWhite)
  gfx.setColor(gfx.kColorBlack)
end

function draw()
  draw_ball()
end

-- LIFECYCLE

function playdate.update()
  handle_input()
  update_physics(1/frame_rate)
  draw()
end

init_game()
