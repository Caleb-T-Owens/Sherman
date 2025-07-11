type Input = Vec<Vec<char>>;

fn get_input() -> Input {
    let input = std::fs::read_to_string("aoc-input.txt").unwrap();
    input
        .lines()
        .map(|line| line.chars().collect::<Vec<_>>())
        .collect::<Vec<_>>()
}

fn one(input: &Input) {
    let mut x = 1;
    let mut y = 1;

    let mut output = vec![];

    for line in input {
        for char in line {
            match char {
                'U' => y = (y - 1).clamp(0, 2),
                'D' => y = (y + 1).clamp(0, 2),
                'L' => x = (x - 1).clamp(0, 2),
                'R' => x = (x + 1).clamp(0, 2),
                _ => unreachable!(),
            }
        }

        output.push(y * 3 + (x + 1))
    }

    dbg!(output);
}

fn dist((x, y): (i64, i64)) -> i64 {
    (x - 2).abs() + (y - 2).abs()
}

fn two(input: &Input) {
    let mut position = (0, 2);

    let mut output = vec![];

    for line in input {
        for char in line {
            let (x, y) = position;
            let new_pos = match char {
                'U' => (x, y - 1),
                'D' => (x, y + 1),
                'L' => (x - 1, y),
                'R' => (x + 1, y),
                _ => unreachable!(),
            };

            if dist(new_pos) <= 2 {
                position = new_pos;
            }
        }

        let button_that_we_probably_pressed = match position {
            (2, 0) => '1',
            (x, 1) => match x {
                1 => '2',
                2 => '3',
                3 => '4',
                _ => unreachable!(),
            },
            (x, 2) => match x {
                0 => '5',
                1 => '6',
                2 => '7',
                3 => '8',
                4 => '9',
                _ => unreachable!(),
            },
            (x, 3) => match x {
                1 => 'A',
                2 => 'B',
                3 => 'C',
                _ => unreachable!(),
            },
            (2, 4) => 'D',
            _ => unreachable!(),
        };

        output.push(button_that_we_probably_pressed)
    }

    dbg!(output);
}

fn main() {
    let input = get_input();
    one(&input);
    two(&input);
}
