use std::{fs, path::PathBuf, process::Command};

fn main() {
    let args = std::env::args().collect::<Vec<_>>();
    let subcommand = args.get(1).expect("subcommand not found");
    match subcommand.as_str() {
        "sync" => sync(),
        "init" => init(),
        other => panic!("Unrecognised subcommand: {}", other),
    }
}

fn aptfile_path() -> PathBuf {
    let base = std::env::current_dir().unwrap();
    base.join("Aptfile")
}

fn aptmark_showmanual() -> Vec<String> {
    let output = Command::new("apt-mark")
        .arg("showmanual")
        .output()
        .unwrap()
        .stdout;

    let output = std::str::from_utf8(&output).unwrap();
    let output = output.lines().map(Into::into).collect::<Vec<_>>();
    output
}

fn aptmark_showauto() -> Vec<String> {
    let output = Command::new("apt-mark")
        .arg("showauto")
        .output()
        .unwrap()
        .stdout;

    let output = std::str::from_utf8(&output).unwrap();
    let output = output.lines().map(Into::into).collect::<Vec<_>>();
    output
}

fn aptmark_manual(package: &str) {
    Command::new("apt-mark")
        .args(["manual", package])
        .spawn()
        .unwrap()
        .wait()
        .unwrap();
}

fn aptmark_auto(package: &str) {
    Command::new("apt-mark")
        .args(["auto", package])
        .spawn()
        .unwrap()
        .wait()
        .unwrap();
}

fn apt_install(package: &str) {
    Command::new("apt")
        .args(["install", package])
        .spawn()
        .unwrap()
        .wait()
        .unwrap();
}

fn apt_purge(package: &str) {
    Command::new("apt")
        .args(["purge", package])
        .spawn()
        .unwrap()
        .wait()
        .unwrap();
}

fn aptcache_rdeps(package: &str) -> bool {
    let output = Command::new("apt-cache")
        .args(["rdeps", "--installed", package])
        .output()
        .unwrap()
        .stdout;

    let output = std::str::from_utf8(&output).unwrap();
    let output_length = output.lines().count();

    // The output consists of two formatting lines and then follows by the
    // list of dependencies.
    output_length > 2
}

fn init() {
    let aptfile_path = aptfile_path();
    if aptfile_path.try_exists().unwrap() {
        panic!("Aptfile already exists in this directory. If you want to re-create your Aptfile, please delete the existing Aptfile first");
    }

    let manual_packages = aptmark_showmanual();
    let aptfile = manual_packages.join("\n");
    fs::write(aptfile_path, aptfile).expect("Failed to write Aptfile");

    println!("Successfully created your new Aptfile!")
}

fn read_aptfile() -> Vec<String> {
    let aptfile_path = aptfile_path();
    let aptfile = fs::read_to_string(aptfile_path).expect("Failed to read Aptfile.");

    aptfile
        .trim()
        .lines()
        .filter(|line| !line.starts_with("#"))
        .map(Into::into)
        .collect()
}

fn sync() {
    let manual_packages = aptmark_showmanual();
    let auto_packages = aptmark_showauto();
    let aptfile_packages = read_aptfile();

    let missing_packages = aptfile_packages
        .iter()
        .filter(|package| !manual_packages.contains(package));


    for package in missing_packages {
        if auto_packages.contains(package) {
            aptmark_manual(package);
        } else {
            apt_install(package);
        }
    }

    let extra_packages = manual_packages
        .iter()
        .filter(|package| !aptfile_packages.contains(package));

    for package in extra_packages {
        if aptcache_rdeps(package) {
            aptmark_auto(package);
        } else {
            apt_purge(package);
        }
    }
}
