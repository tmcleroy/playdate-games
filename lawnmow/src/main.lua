import "CoreLibs/graphics"
import "util"

local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

-- INIT

function init_game()
  frame_rate = 50 -- max refresh rate of playdate screen

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
  crank_angle_rot = 90

  -- ball
  ball_dim = {20,20}
  ball_vel_initial = {0,0}
  ball_pos_initial = {(window_dim[1] / 2) - (ball_dim[1] / 2), (window_dim[2] / 2) - (ball_dim[2] / 2)} -- center of screen
  ball_pos = ball_pos_initial
  ball_vel = ball_vel_initial
  ball_vel_max = 3
  ball_speed = 2
  min_ball_speed = 1
  max_ball_speed = 3

  init_sounds()
  init_sprites()
  init_zone_map()
  draw_bg()
end

function init_sprites()
  ball_img = gfx.image.new('img/ball.png')
  white_img = gfx.image.new('img/white.png')
  black_img = gfx.image.new('img/black.png')
  grass_img = gfx.image.new('img/grass.png')
  fine_horizontal_stripes_img = gfx.image.new('img/fine_horizontal_stripes.png')
end

function init_sounds()
end

function init_zone_map()
  total_zones = 0
  zone_size = 10 -- pixels
  zone_map = {}
  -- fill zone map 2d array with empty spaces (zeroes)
  for i = 0, window_dim[1], zone_size do
    zone_map[i + 1] = {}
    for j = 0, window_dim[2], zone_size do
      zone_map[i + 1][j + 1] = 0
      total_zones = total_zones + 1
    end
  end
end

-- INPUT

function handle_input()
  if playdate.buttonJustPressed(playdate.kButtonDown) then
    ball_speed = math.max(ball_speed - 1, min_ball_speed)
  end
  if playdate.buttonJustPressed(playdate.kButtonUp) then
    ball_speed = math.min(ball_speed + 1, max_ball_speed)
  end

  crank_angle = playdate.getCrankPosition()
  crank_paddle_vel = playdate.getCrankChange()
end

-- PHYSICS

function update_physics(dt)
  handle_collisions(dt)
  rad = math.rad(crank_angle - crank_angle_rot)
  ball_vec = {
    ball_pos[1] + ball_vel[1] * dt * speed_mult,
    ball_pos[2] + ball_vel[2] * dt * speed_mult
  }

  crank_vec = {math.cos(rad), math.sin(rad)}
  ball_pos = get_valid_ball_pos({
    ball_vec[1] + crank_vec[1]  * ball_speed,
    ball_vec[2] + crank_vec[2]  * ball_speed
  })
end

function handle_collisions()
  -- wall collision
  local collide_top = ball_pos[2] <= 0
  local collide_bottom = ball_pos[2] >= window_dim[2] - ball_dim[2]
  local collide_left = ball_pos[1] <= 0
  local collide_right = ball_pos[1] >= window_dim[1] - ball_dim[1]
  local collided_with_wall = collide_top or collide_bottom or collide_left or collide_right
end

-- keep ball within playing area
function get_valid_ball_pos(ball_pos)
  if ball_pos[1] < 0 then
    ball_pos[1] = 0
  end
  if ball_pos[1] > window_dim[1] - ball_dim[1] then
    ball_pos[1] = window_dim[1] - ball_dim[1]
  end
  if ball_pos[2] < 0 then
    ball_pos[2] = 0
  end
  if ball_pos[2] > window_dim[2] - ball_dim[2] then
    ball_pos[2] = window_dim[2] - ball_dim[2]
  end
  return ball_pos
end

function update_zones()
  for i = 0, window_dim[1], zone_size do
    for j = 0, window_dim[2], zone_size do
      if
        ((ball_pos[1] >= i and ball_pos[1] <= i + zone_size) and (ball_pos[2] >= j and ball_pos[2] <= j + zone_size)) or
        ((ball_pos[1] + ball_dim[1] >= i and ball_pos[1] + ball_dim[1] <= i + zone_size) and (ball_pos[2] + ball_dim[2] >= j and ball_pos[2] + ball_dim[2] <= j + zone_size)) or
        ((ball_pos[1] + ball_dim[1] >= i and ball_pos[1] + ball_dim[1] <= i + (zone_size * (ball_dim[1] / zone_size))) and (ball_pos[2] + ball_dim[2] >= j and ball_pos[2] + ball_dim[2] <= j + (zone_size * (ball_dim[1] / zone_size))))
      then
        zone_map[i + 1][j + 1] = 1
      end
    end
  end
  set_score()
end

function set_score()
  local occupied_zones = 0
  for i = 0, window_dim[1], zone_size do
    for j = 0, window_dim[2], zone_size do
      if zone_map[i + 1][j + 1] == 1 then
        occupied_zones = occupied_zones + 1
      end
    end
  end
  score = math.ceil((occupied_zones / total_zones) * 100)
end

-- DRAWING

function draw_bg()
  fine_horizontal_stripes_img.draw(fine_horizontal_stripes_img, 0, 0)
end

function draw_zones()
  for i = 0, window_dim[1], zone_size do
    for j = 0, window_dim[2], zone_size do
      grass_img.drawScaled(grass_img, i, j, zone_size / ball_dim[1])
      if zone_map[i + 1][j + 1] == 1 then
        white_img.drawScaled(white_img, i, j, zone_size / ball_dim[1])
      end
    end
  end
end

function draw_ball()
  if prev_x and prev_y and prev_crank_angle then
    -- draw white tile where lawnmower was previously to simulate grass being removed
    white_img.drawRotated(white_img, prev_x, prev_y, prev_crank_angle)
  end
  ball_img.drawRotated(ball_img, ball_pos[1] + (ball_dim[1] / 2), ball_pos[2] + (ball_dim[2] / 2), crank_angle)
  prev_x = ball_pos[1] + (ball_dim[1] / 2)
  prev_y = ball_pos[2] + (ball_dim[2] / 2)
  prev_crank_angle = crank_angle
end

function draw_white_bg()
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(0, 0, window_dim[1], window_dim[2])
  gfx.setBackgroundColor(gfx.kColorWhite)
  gfx.setColor(gfx.kColorBlack)
end

function draw_score()
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(0, 0, 50, 20)
  gfx.drawText(score .. "%", 5, 2)
end

function draw_speed()
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(window_dim[1] - 50, 0, 50, 20)
  gfx.drawText("SPD: " .. ball_speed, window_dim[1] - 48, 2)
end

function draw_hud()
  draw_score()
  draw_speed()
end

function draw()
  draw_hud()
  draw_ball()
end

-- LIFECYCLE

function playdate.update()
  handle_input()
  update_physics(1/frame_rate)
  update_zones()
  set_score()
  draw()
end

init_game()
