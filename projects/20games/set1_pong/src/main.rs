use raylib::{
    color::Color,
    ffi::{KeyboardKey, WindowShouldClose},
    math::Vector2,
    prelude::RaylibDraw as _,
};

const WIDTH: i32 = 500;
const HEIGHT: i32 = 700;

struct Ball {
    radius: f32,
    position: Vector2,
    movement: Vector2,
}

/// Padel: Has a size, centered around the position
struct Padel {
    size: Vector2,
    /// Center of the padel
    position: Vector2,
    movement_speed: f32,
}

impl Ball {
    fn handle_padel_interaction(&mut self, padel: &Padel) {
        if !self.is_interspecting_padel(padel) {
            return;
        }

        self.movement.y *= -1.0;

        self.movement.x += -(padel.position.x - self.position.x) / padel.size.x / 2.0 * 500.0;

        // ensure ball is outside of the padel
        let distance = self.position.y - padel.position.y;
        let desired = self.radius + padel.size.y / 2.0;
        if distance < 0.0 {
            self.position.y = padel.position.y - desired - 2.0;
        } else {
            self.position.y = padel.position.y + desired + 2.0;
        }
    }

    fn is_interspecting_padel(&self, padel: &Padel) -> bool {
        let top_p = padel.position.y - padel.size.y / 2.0;
        let bottom_p = padel.position.y + padel.size.y / 2.0;
        let left_p = padel.position.x - padel.size.x / 2.0;
        let right_p = padel.position.x + padel.size.x / 2.0;

        if top_p < self.position.y + self.radius
            && bottom_p > self.position.y - self.radius
            && left_p < self.position.x + self.radius
            && right_p > self.position.x - self.radius
        {
            return true;
        }

        false
    }
}

enum GameState {
    Running,
    Over { player_won: bool },
}

fn main() {
    let (mut rl, thread) = raylib::init().size(WIDTH, HEIGHT).title("Pong").build();

    // 2 padels
    // the ball

    let mut ball = Ball {
        radius: 10.0,
        position: Vector2 {
            x: (WIDTH / 2) as f32,
            y: (HEIGHT / 2) as f32,
        },
        movement: Vector2 { x: 250.0, y: 250.0 },
    };

    let mut player_padel = Padel {
        size: Vector2 { x: 100.0, y: 10.0 },
        position: Vector2 {
            x: (WIDTH / 2) as f32,
            y: (HEIGHT - 30) as f32,
        },
        movement_speed: 270.0,
    };

    let mut ai_padel = Padel {
        size: Vector2 { x: 100.0, y: 10.0 },
        position: Vector2 {
            x: (WIDTH / 2) as f32,
            y: 30.0,
        },
        movement_speed: 250.0,
    };

    let mut game_state = GameState::Running;

    while !rl.window_should_close() {
        let tx = rl.get_frame_time();
        let mut d = rl.begin_drawing(&thread);

        d.clear_background(Color::BLACK);

        match game_state {
            GameState::Running => {
                // Draw the ball.
                d.draw_circle(
                    ball.position.x as i32,
                    ball.position.y as i32,
                    ball.radius,
                    Color::WHITE,
                );

                ball.position += ball.movement * tx;

                if ball.position.x <= 0.0 {
                    ball.position.x = 0.0;
                    ball.movement.x *= -1.0;
                }
                if ball.position.x >= WIDTH as f32 {
                    ball.position.x = WIDTH as f32;
                    ball.movement.x *= -1.0;
                }

                if ball.position.y >= HEIGHT as f32 {
                    game_state = GameState::Over { player_won: false }
                }
                if ball.position.y <= 0.0 {
                    game_state = GameState::Over { player_won: true }
                }

                // Draw padel
                for p in [&player_padel, &ai_padel] {
                    d.draw_rectangle(
                        (p.position.x - p.size.x / 2.0) as i32,
                        (p.position.y - p.size.y / 2.0) as i32,
                        p.size.x as i32,
                        p.size.y as i32,
                        Color::WHITE,
                    );

                    ball.handle_padel_interaction(p);
                }

                if d.is_key_down(KeyboardKey::KEY_D) {
                    player_padel.position.x += player_padel.movement_speed * tx;
                }
                if d.is_key_down(KeyboardKey::KEY_A) {
                    player_padel.position.x -= player_padel.movement_speed * tx;
                }

                if ai_padel.position.x < ball.position.x {
                    ai_padel.position.x += ai_padel.movement_speed * tx;
                } else {
                    ai_padel.position.x -= ai_padel.movement_speed * tx;
                }
            }
            GameState::Over { player_won } => {
                d.draw_text(
                    &format!("Game over. You {}", if player_won { "won" } else { "lost" }),
                    20,
                    20,
                    25,
                    Color::WHITE,
                );
            }
        }
    }
}
