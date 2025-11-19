use anyhow::Result;
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};

#[derive(Parser, Debug)]
#[command(version = "0.1.0", about, long_about = None)]
struct Args {
    #[clap(subcommand)]
    subcommand: Subcmd,
}

#[derive(Subcommand, Debug)]
enum Subcmd {
    /// This will add a new wine
    Add {
        #[clap(short = 'n')]
        name: String,
        #[clap(short = 'r')]
        rating: f32,
    },
    List,
}

fn main() -> Result<()> {
    let args = Args::parse();

    match args.subcommand {
        Subcmd::Add { name, rating } => add(&name, rating)?,
        Subcmd::List => list()?,
    }

    Ok(())
}

#[derive(Serialize, Deserialize)]
struct Wine {
    name: String,
    rating: f32,
}

fn read_storage() -> Result<Vec<Wine>> {
    let contents = std::fs::read_to_string("/tmp/wines.json")?;
    let contents = serde_json::from_str(&contents)?;
    Ok(contents)
}

fn write_storage(wines: &[Wine]) -> Result<()> {
    let contents = serde_json::to_string(wines)?;
    std::fs::write("/tmp/wines.json", contents)?;

    Ok(())
}

fn add(name: &str, rating: f32) -> Result<()> {
    let mut storage = read_storage().unwrap_or(vec![]);

    storage.push(Wine {
        name: name.into(),
        rating,
    });

    write_storage(&storage)?;

    println!("Added scott's next wine");

    Ok(())
}

fn list() -> Result<()> {
    let storage = read_storage()?;

    for wine in storage {
        println!("wine {}, rating: {}", wine.name, wine.rating);
    }

    Ok(())
}
