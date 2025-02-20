use rand::prelude::*;
// Course generation:
//
// Has a start and an end
//
// 10y + 20x;
//
// Grass types:
// - Wild grass: #
// - Fairways: ,
// - Putting greens: .
// - Sand bunker: %
// - Tree: $
// - Water: ~
// - Flag: F
// - Start: S
//
// We generae a combination of fw, pg, sb, t, and w, and then overlay the start and end

// CLI:
// golf init; Creates a new game in the current directory
// golf show; Shows the current game state
// golf strike d|w|p -a <angle (0..=360)> -p <power (0..=100)>

struct SceneBuilder {}

fn build_weight_map() -> Vec<Vec<f32>> {
    let mut out = vec![];

    for _ in 0..10 {
        out.push(vec![]);

        for _ in 0..20 {
            out.last_mut().unwrap().push(rand::random());
        }
    }

    out
}

fn weight_map_to_tiles(map: &Vec<Vec<f32>>) -> Vec<Vec<Tile>> {
    let mut out = vec![];

    for row in map {
        out.push(vec![]);

        for weight in row {
            if *weight < 0.25 {
                out.last_mut().unwrap().push(Tile::Water);
            } else if *weight < 0.40 {
                out.last_mut().unwrap().push(Tile::WildGrass);
            } else if *weight < 0.59 {
                out.last_mut().unwrap().push(Tile::Fairway);
            } else {
                out.last_mut().unwrap().push(Tile::PuttingGreen);
            }
        }
    }

    out
}

fn smooth_weight_map(map: &Vec<Vec<f32>>) -> Vec<Vec<f32>> {
    let mut out = vec![];

    let ys = map.len();
    let xs = map.first().unwrap().len();

    for y in 0..ys {
        out.push(vec![]);

        for x in 0..xs {
            let e = vec![];
            let a = if y == 0 {
                &0.0
            } else {
                map.get(y - 1).unwrap_or(&e).get(x).unwrap_or(&0.0)
            };
            let b = map.get(y + 1).unwrap_or(&e).get(x).unwrap_or(&0.0);
            let c = if x == 0 {
                &0.0
            } else {
                map.get(y).unwrap_or(&e).get(x - 1).unwrap_or(&0.0)
            };
            let d = map.get(y).unwrap_or(&e).get(x + 1).unwrap_or(&0.0);
            let t = map.get(y).unwrap_or(&e).get(x).unwrap_or(&0.0);

            out.last_mut().unwrap().push((a + b + c + d + t) / 5.0);
        }
    }

    out
}

fn replace_above_threshold(
    tiles: &mut Vec<Vec<Tile>>,
    map: &Vec<Vec<f32>>,
    threshold: f32,
    tile: Tile,
) {
    for (y, row) in map.iter().enumerate() {
        for (x, value) in row.iter().enumerate() {
            if *value > threshold {
                tiles[y][x] = tile;
            }
        }
    }
}

fn replace_one_of<R: Rng>(
    rng: &mut R,
    map: &mut Vec<Vec<Tile>>,
    kind: Tile,
    with: Tile,
) {
    let mut candidates = vec![];

    for (y, row) in map.iter().enumerate() {
        for (x, tile) in row.iter().enumerate() {
            if *tile == kind {
                candidates.push((x, y));
            }
        }
    }

    if candidates.is_empty() {
        candidates.push((5, 5));
    }

    let (x, y) = candidates.choose(rng).unwrap();

    map[*y][*x] = with;
}

impl SceneBuilder {
    fn new() -> Self {
        Self {}
    }

    fn build(self) -> Scene {
        let weight_map = build_weight_map();
        let weight_map = smooth_weight_map(&weight_map);
        let weight_map = smooth_weight_map(&weight_map);

        let mut tiles = weight_map_to_tiles(&weight_map);

        let tree_map = build_weight_map();
        let tree_map = smooth_weight_map(&tree_map);

        replace_above_threshold(&mut tiles, &tree_map, 0.7, Tile::Tree);

        let bunker_map = build_weight_map();
        let bunker_map = smooth_weight_map(&bunker_map);
        let bunker_map = smooth_weight_map(&bunker_map);

        replace_above_threshold(&mut tiles, &bunker_map, 0.65, Tile::Sand);

        let mut rng = rand::rng();
        replace_one_of(&mut rng, &mut tiles, Tile::PuttingGreen, Tile::Flag);
        replace_one_of(&mut rng, &mut tiles, Tile::Fairway, Tile::Start);

        Scene { tiles }
    }
}

#[derive(Copy, Clone, PartialEq)]
enum Tile {
    WildGrass,
    Fairway,
    PuttingGreen,
    Sand,
    Tree,
    Water,
    Flag,
    Start,
}

impl Tile {
    fn to_string(&self) -> String {
        match self {
            Self::WildGrass => "#",
            Self::Fairway => ",",
            Self::PuttingGreen => ".",
            Self::Sand => "%",
            Self::Tree => "$",
            Self::Water => "~",
            Self::Flag => "F",
            Self::Start => "S",
        }
        .to_owned()
    }
}

struct Scene {
    tiles: Vec<Vec<Tile>>,
}

impl Scene {
    fn display(&self) {
        for row in &self.tiles {
            for tile in row {
                print!("{}", tile.to_string());
            }
            print!("\n");
        }
    }
}

fn main() {
    SceneBuilder::new().build().display();
}
