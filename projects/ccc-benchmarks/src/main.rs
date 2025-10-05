use std::{
    collections::HashSet,
    fs::OpenOptions,
    io::Write as _,
    path::Path,
    process::Command,
    time::{Duration, Instant},
};

use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    GenerateReport,
    BasicStats,
    ToCsv,
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::GenerateReport => generate_report(),
        Commands::BasicStats => basic_stats(),
        Commands::ToCsv => to_csv(),
    };
}

fn to_csv() {
    let reports = std::fs::read_to_string("output.jsonl")
        .unwrap()
        .lines()
        .map(|l| serde_json::from_str::<ReportLine>(l).unwrap())
        .filter(|r| r.length > 0)
        .collect::<Vec<_>>();

    let _ = std::fs::remove_file("output.csv");
    let mut output = OpenOptions::new()
        .create(true)
        .append(true)
        .open("output.csv")
        .unwrap();

    for r in reports {
        let ReportLine {
            file,
            normal,
            in_commits,
            in_commits_duration,
            c,
            cc,
            ccc,
            length,
        } = r;
        writeln!(
            &mut output,
            "{file}, {in_commits}, {length}, {}, {}, {}, {}, {}",
            in_commits_duration.as_millis(),
            normal.as_millis(),
            c.as_millis(),
            cc.as_millis(),
            ccc.as_millis()
        )
        .unwrap();
    }
}

fn basic_stats() {
    let reports = std::fs::read_to_string("output.jsonl")
        .unwrap()
        .lines()
        .map(|l| serde_json::from_str::<ReportLine>(l).unwrap())
        .filter(|r| r.length != -1)
        .collect::<Vec<_>>();

    println!(
        "mean normal: {}",
        reports.iter().map(|r| r.normal.as_millis()).sum::<u128>() as f64 / reports.len() as f64
    );
    println!(
        "mean c: {}",
        reports.iter().map(|r| r.c.as_millis()).sum::<u128>() as f64 / reports.len() as f64
    );
    println!(
        "mean cc: {}",
        reports.iter().map(|r| r.cc.as_millis()).sum::<u128>() as f64 / reports.len() as f64
    );
    println!(
        "mean ccc: {}",
        reports.iter().map(|r| r.ccc.as_millis()).sum::<u128>() as f64 / reports.len() as f64
    );

    medians(&reports);
}

fn medians(reports: &[ReportLine]) {
    let mut normals = reports
        .iter()
        .map(|r| r.normal.as_millis())
        .collect::<Vec<_>>();
    normals.sort();
    let mut cs = reports.iter().map(|r| r.c.as_millis()).collect::<Vec<_>>();
    cs.sort();
    let mut ccs = reports.iter().map(|r| r.cc.as_millis()).collect::<Vec<_>>();
    ccs.sort();
    let mut cccs = reports
        .iter()
        .map(|r| r.ccc.as_millis())
        .collect::<Vec<_>>();
    cccs.sort();
    println!("median normal: {}", normals[reports.len() / 2]);
    println!("median c: {}", cs[reports.len() / 2]);
    println!("median cc: {}", ccs[reports.len() / 2]);
    println!("median ccc: {}", cccs[reports.len() / 2]);
    println!(
        "75% normal: {}",
        normals[(reports.len() as f64 * 0.75) as usize]
    );
    println!("75% c: {}", cs[(reports.len() as f64 * 0.75) as usize]);
    println!("75% cc: {}", ccs[(reports.len() as f64 * 0.75) as usize]);
    println!("75% ccc: {}", cccs[(reports.len() as f64 * 0.75) as usize]);
    println!(
        "95% normal: {}",
        normals[(reports.len() as f64 * 0.95) as usize]
    );
    println!("95% c: {}", cs[(reports.len() as f64 * 0.95) as usize]);
    println!("95% cc: {}", ccs[(reports.len() as f64 * 0.95) as usize]);
    println!("95% ccc: {}", cccs[(reports.len() as f64 * 0.95) as usize]);
}

fn generate_report() {
    let files = Command::new("git")
        .current_dir("example-repo")
        .args(["ls-tree", "-r", "HEAD"])
        .output()
        .unwrap()
        .stdout;
    let files = String::from_utf8(files).unwrap();
    let files = files
        .lines()
        .map(|l| l.split_whitespace().collect::<Vec<_>>()[3].to_owned())
        .collect::<Vec<_>>();
    let already_processed = std::fs::read_to_string("output.jsonl")
        .unwrap()
        .lines()
        .map(|l| serde_json::from_str::<ReportLine>(l).unwrap().file)
        .collect::<HashSet<_>>();
    let to_process = files
        .into_iter()
        .filter(|f| !already_processed.contains(f))
        .collect::<Vec<_>>();
    let mut output = OpenOptions::new()
        .create(true)
        .append(true)
        .open("output.jsonl")
        .unwrap();
    for file in to_process {
        let length = std::fs::read_to_string(Path::new("example-repo").join(&file))
            .map(|f| f.lines().count() as i64)
            .unwrap_or(-1);

        let start = Instant::now();
        let in_commits = Command::new("git")
            .current_dir("example-repo")
            .args(["log", "--oneline", "--", &file])
            .output()
            .unwrap()
            .stdout;
        let in_commits_duration = start.elapsed();
        let in_commits = String::from_utf8(in_commits).unwrap().lines().count();
        let start = Instant::now();
        Command::new("git")
            .current_dir("example-repo")
            .args(["blame", &file])
            .output()
            .unwrap();
        let normal = start.elapsed();
        let start = Instant::now();
        Command::new("git")
            .current_dir("example-repo")
            .args(["blame", "-C", &file])
            .output()
            .unwrap();
        let c = start.elapsed();
        let start = Instant::now();
        Command::new("git")
            .current_dir("example-repo")
            .args(["blame", "-C", "-C", &file])
            .output()
            .unwrap();
        let cc = start.elapsed();
        let start = Instant::now();
        Command::new("git")
            .current_dir("example-repo")
            .args(["blame", "-C", "-C", "-C", &file])
            .output()
            .unwrap();
        let ccc = start.elapsed();

        let report = ReportLine {
            file: file.to_string(),
            length,
            normal,
            in_commits,
            in_commits_duration,
            c,
            cc,
            ccc,
        };
        dbg!(&report);
        writeln!(&mut output, "{}", serde_json::to_string(&report).unwrap()).unwrap();
    }
}

#[derive(Debug, Deserialize, Serialize)]
struct ReportLine {
    file: String,
    normal: Duration,
    in_commits: usize,
    in_commits_duration: Duration,
    c: Duration,
    cc: Duration,
    ccc: Duration,
    length: i64,
}
