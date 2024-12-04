use solution_0001::Solution0001;
use solution_0002::Solution0002;
use solution_0003::Solution0003;

mod solution_0001;
mod solution_0002;
mod solution_0003;

pub trait Problem {
    fn id(&self) -> String;
    fn run(&self) -> String;
}

fn main() {
    println!("Hello, world!");

    let solutions: Vec<&dyn Problem> = vec![&Solution0001, &Solution0002, &Solution0003];

    for solution in solutions {
        println!("{}: {}", solution.id(), solution.run());
    }
}
