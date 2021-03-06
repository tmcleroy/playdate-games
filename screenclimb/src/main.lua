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

  -- feature bools
  end_game_on_wall_collision = true

  -- feature vals
  speed_mult = 70 -- value to multiply dt by for consistent game speed across devices

  -- score
  score = 0
  score_increase_per_ball_rotation = 1 -- number of points to increase score per full ball rotation

  -- crank
  crank_step_amount = 6
  crank_angle = 0
  crank_paddle_vel = 0 -- used to calculate paddle velocity for transfering to rotation of ball

  -- ball
  ball_dim = {20,20}
  ball_angle = 0
  ball_angle_vel = 0
  ball_angle_diff = 0
  ball_vel_initial = {0,0}
  ball_pos_initial = {(window_dim[1] / 2) - (ball_dim[1] / 2), (window_dim[2] / 2) - (ball_dim[2] / 2)} -- center of screen
  ball_pos = ball_pos_initial
  ball_vel = ball_vel_initial
  ball_vel_max = 3
  ball_paddle_rotation_transfer = 0.1 -- amount of paddle velocity to transfer to ball rotation on collision
  colliding_paddles = {} -- track previous frame collisions so ball can be reset when it's stuck

  -- paddle
  paddle_speed = 0
  paddle_decrease_amount = 10 -- number of pixels to decrease the paddle width on ball collision
  paddle_decreases = 0 -- number of times the paddle size has been decreased due to collison with ball

  paddle_width_initial = 200
  paddle_height = 20
  paddle_width = paddle_width_initial
  paddle_dim = {
    bottom = {paddle_width,paddle_height},
    left = {paddle_height,paddle_width},
    right = {paddle_height,paddle_width},
    top = {paddle_width,paddle_height}
  }

  -- paddle_border_radius = 0 -- square
  paddle_border_radius = paddle_height / 2 -- round

  paddle_pos = {
    bottom = { -- bottom center
      (window_dim[1] / 2) - (paddle_dim.bottom[1] / 2),
      window_dim[2] - paddle_dim.bottom[2]
    },
    left = { 0, window_dim[2] - paddle_dim.left[2] },
    right = { window_dim[1] - paddle_dim.right[1], 0 },
    top = { 0, 0 }
  }
end

function init_sprites()
  ball_img = gfx.image.new('img/ball.png')
end

function init_sounds()
  boom_sound = sound.sampleplayer.new("sound/boom.wav")
  ping_sound = sound.sampleplayer.new("sound/ping.wav")
  plink_sound = sound.sampleplayer.new("sound/plink.wav")
end

-- INPUT

function handle_input()
  if playdate.buttonIsPressed(playdate.kButtonDown) then
    ball_vel[2] = 2
  end
  if playdate.buttonIsPressed(playdate.kButtonUp) then
    ball_vel[2] = -2
  end
  if playdate.buttonIsPressed(playdate.kButtonRight) then
    ball_vel[1] = 2
  end
  if playdate.buttonIsPressed(playdate.kButtonLeft) then
    ball_vel[1] = -2
  end

  crank_angle = playdate.getCrankPosition()
  crank_paddle_vel = playdate.getCrankChange()
end

-- PHYSICS

function update_physics(dt)
  -- ball
  adjust_ball_velocity(dt)
  ball_pos = {ball_pos[1] + ball_vel[1] * dt * speed_mult, ball_pos[2] + ball_vel[2] * dt * speed_mult}
  local prev_ball_angle = ball_angle
  ball_angle = ball_angle + ball_angle_vel * dt * speed_mult
  local ball_diff = math.abs(ball_angle - prev_ball_angle) * 10

  -- increase score every tenth of a rotation for a total of score_increase_per_ball_rotation points per full rotation
  ball_angle_diff = (ball_angle_diff + ball_diff * 10)
  if (ball_angle_diff >= 64) then
    ball_angle_diff = 0
    score = score + score_increase_per_ball_rotation / 10
    sound.sampleplayer.play(plink_sound)
  end

  local bottom_pos =
    -- bottom_pos should range from -800 to 1200, convert the angle value to a number in that range
                                          -- move the paddle so it stays centered when its width decreases
      -800 + ((crank_angle / 359) * 1200) + (paddle_decreases * (paddle_decrease_amount / 2))

  local paddle_diff = (paddle_width - (window_dim[1] / 2))
  local left_pos = paddle_pos.bottom[1] + (window_dim[2] - paddle_height)
  local right_pos = (window_dim[1] + paddle_height - paddle_diff ) - bottom_pos
  local top_pos = (bottom_pos >= -(window_dim[1] + paddle_diff) and -1 or 1) * math.abs(bottom_pos + (window_dim[1] + paddle_diff))

  if (bottom_pos <= -580) then
    right_pos = -200 - paddle_diff + math.abs(bottom_pos + 580)
  end

  paddle_pos.bottom[1] = bottom_pos
  paddle_pos.left[2] = left_pos
  paddle_pos.right[2] = right_pos
  paddle_pos.top[1] = top_pos
end

function adjust_ball_velocity()
  -- wall collision
  local collide_top = ball_pos[2] <= 0
  local collide_bottom = ball_pos[2] >= window_dim[2] - ball_dim[2]
  local collide_left = ball_pos[1] <= 0
  local collide_right = ball_pos[1] >= window_dim[1] - ball_dim[1]
  local collided_with_wall = collide_top or collide_bottom or collide_left or collide_right
  local small_rand_range = math.random(-10, 10) / 60


  if (collided_with_wall and end_game_on_wall_collision) then
    sound.sampleplayer.play(boom_sound)
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
        sound.sampleplayer.play(ping_sound)
        if (k == "bottom") then
          --                               increase ball vel with each paddle hit
          ball_vel[2] = -1 * ball_vel[2] - math.abs(small_rand_range * 1.5)
          ball_vel[1] = ball_vel[1] + (crank_paddle_vel / math.random(crank_step_amount - 1, crank_step_amount + 1)) + small_rand_range
        end
        if (k == "top") then
          ball_vel[2] = -1 * ball_vel[2] + math.abs(small_rand_range * 1.5)
          ball_vel[1] = ball_vel[1] - (crank_paddle_vel / math.random(crank_step_amount - 1, crank_step_amount + 1)) + small_rand_range
        end
        if (k == "left") then
          ball_vel[1] = -1 * ball_vel[1] + math.abs(small_rand_range * 1.5)
          ball_vel[2] = ball_vel[2] + (crank_paddle_vel / math.random(crank_step_amount - 1, crank_step_amount + 1)) + small_rand_range
        end
        if (k == "right") then
          ball_vel[1] = -1 * ball_vel[1] - math.abs(small_rand_range * 1.5)
          ball_vel[2] = ball_vel[2] - (crank_paddle_vel / math.random(crank_step_amount - 1, crank_step_amount + 1)) + small_rand_range
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
    paddle_pos.bottom[1] <= (window_dim[1] - paddle_height) and paddle_pos.bottom[1] >= -(paddle_width - paddle_height)
  local left =
    paddle_pos.left[2] <= (window_dim[2] - paddle_height) and paddle_pos.left[2] >= -(paddle_width - paddle_height)
  local right =
  paddle_pos.right[2] <= (window_dim[2] - paddle_height) and paddle_pos.right[2] >= -(paddle_width - paddle_height)
  local top =
    paddle_pos.top[1] <= (window_dim[1] - paddle_height) and paddle_pos.top[1] >= - (paddle_width - paddle_height)

  return { bottom = bottom, left = left, right = right, top = top }
  -- return { bottom = true, left = true, right = true, top = true }
end

-- DRAWING

function draw_ball()
  ball_img.drawRotated(ball_img, ball_pos[1] + (ball_dim[1] / 2), ball_pos[2] + (ball_dim[2] / 2), ball_angle * 150)
end

function draw_paddles()
  for k, v in pairs(visible_paddles) do
    if visible_paddles[k] then
      gfx.fillRoundRect(paddle_pos[k][1], paddle_pos[k][2], paddle_dim[k][1], paddle_dim[k][2], paddle_border_radius)
    end
  end
end

function draw_score()
  gfx.drawText(score, 5, 2)
end

function draw_background()
  gfx.setColor(gfx.kColorWhite)
  gfx.fillRect(0, 0, window_dim[1], window_dim[2])
  gfx.setBackgroundColor(gfx.kColorWhite)
  gfx.setColor(gfx.kColorBlack)
end

function draw()
  draw_background()
  draw_paddles()
  draw_ball()
  draw_score()
end

-- LIFECYCLE

function playdate.update()
  visible_paddles = get_visible_paddles()
  handle_input()
  update_physics(1/frame_rate)
  draw()
end

init_game()
