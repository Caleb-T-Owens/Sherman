use std::{env, fs::File, path::Path};

fn main() {
    let args = env::args().collect::<Vec<_>>();
    let path_string = args.get(1).expect("First argument should be a path");
    let path = Path::new(path_string);
    if path.try_exists().expect("Strange fuckup occured") {
        panic!("A file already exists at this location");
    }
    File::create(path).expect("Failed to create file");

    println!("Created empty file at: {}", path_string);
}
