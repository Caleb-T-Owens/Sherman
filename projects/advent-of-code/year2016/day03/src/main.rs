use std::str::FromStr;

#[derive(Default, Clone, PartialEq, Eq, PartialOrd, Ord)]
struct Triangle {
    pub sides: (usize, usize, usize),
}

impl Triangle {
    fn is_valid(&self) -> bool {
        let (a, b, c) = self.sides;

        a + b > c
    }
}

impl From<(usize, usize, usize)> for Triangle {
    fn from(sides: (usize, usize, usize)) -> Self {
        Triangle { sides }
    }
}

impl FromStr for Triangle {
    type Err = ();
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut sides = s
            .split_whitespace()
            .map(|side| side.parse::<usize>().unwrap())
            .collect::<Vec<_>>();

        sides.sort();

        let [a, b, c] = sides.as_slice() else {
            unreachable!()
        };

        Ok(Triangle {
            sides: (*a, *b, *c),
        })
    }
}

fn get_input_1() -> Vec<Triangle> {
    let input = std::fs::read_to_string("aoc-input.txt").unwrap();
    input.lines().map(|l| l.parse().unwrap()).collect()
}

fn one() {
    let input = get_input_1();

    let amount_of_hopefully_maybe_we_dont_know_for_sure_valid_triangles =
        input.into_iter().filter(Triangle::is_valid).count();

    println!("{amount_of_hopefully_maybe_we_dont_know_for_sure_valid_triangles}")
}

fn get_input_2() -> Vec<Triangle> {
    let input = std::fs::read_to_string("aoc-input.txt").unwrap();

    let mut first = vec![];
    let mut second = vec![];
    let mut third = vec![];

    for line in input.lines() {
        let line = line
            .split_whitespace()
            .map(|col| col.parse::<usize>().unwrap())
            .collect::<Vec<_>>();

        first.push(line[0]);
        second.push(line[1]);
        third.push(line[2]);
    }

    first.append(&mut second);
    first.append(&mut third);

    let mut triangles = vec![];

    for i in 0..first.len() / 3 {
        let mut vals = first[i * 3..=i * 3 + 2].to_vec();
        vals.sort();
        let a = vals[0];
        let b = vals[1];
        let c = vals[2];

        triangles.push((a, b, c).into());
    }

    triangles
}

fn two() {
    let input = get_input_2();
    let amount_of_hopefully_maybe_we_dont_know_for_sure_valid_triangles =
        input.into_iter().filter(Triangle::is_valid).count();

    println!("{amount_of_hopefully_maybe_we_dont_know_for_sure_valid_triangles}")
}

fn main() {
    one();
    two();
}
