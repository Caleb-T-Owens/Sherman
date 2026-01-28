use anyhow::{bail, Context, Result};
use clap::Parser;
use colored::*;
use serde::Deserialize;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

/// Configure - A CLI tool for managing configset installations with dependencies
#[derive(Parser, Debug)]
#[command(name = "configure")]
#[command(version, about, long_about = None)]
struct Args {
    /// Path to a configurable.yaml file to run
    #[arg(value_name = "FILE")]
    config_file: Option<PathBuf>,

    /// Run a specific task by name (searches in configsets/)
    #[arg(short = 't', long = "task")]
    task: Option<String>,

    /// Skip running dependencies
    #[arg(long = "no-deps", default_value = "false")]
    no_deps: bool,

    /// Dry run - show what would be executed without running
    #[arg(short = 'n', long = "dry-run", default_value = "false")]
    dry_run: bool,

    /// List all available tasks
    #[arg(short = 'l', long = "list", default_value = "false")]
    list: bool,

    /// Base directory for configsets (default: ./configsets or auto-detected)
    #[arg(long = "configsets-dir")]
    configsets_dir: Option<PathBuf>,
}

#[derive(Debug, Deserialize, Clone)]
struct Configurable {
    /// Name of this configurable (used for identification)
    name: String,
    /// Path to the script to run (relative to configurable.yaml location)
    script: String,
    /// Dependencies - paths to other configurables (relative to configsets root)
    #[serde(default)]
    dependencies: Vec<String>,
    /// Optional description
    #[serde(default)]
    description: Option<String>,
}

impl Configurable {
    fn load(path: &Path) -> Result<Self> {
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read {}", path.display()))?;
        let config: Configurable = serde_yaml::from_str(&content)
            .with_context(|| format!("Failed to parse {}", path.display()))?;
        Ok(config)
    }
}

struct ConfigureRunner {
    configsets_dir: PathBuf,
    configurables: HashMap<String, (PathBuf, Configurable)>,
    completed: HashSet<String>,
    dry_run: bool,
}

impl ConfigureRunner {
    fn new(configsets_dir: PathBuf, dry_run: bool) -> Self {
        Self {
            configsets_dir,
            configurables: HashMap::new(),
            completed: HashSet::new(),
            dry_run,
        }
    }

    /// Discover all configurable.yaml files in the configsets directory
    fn discover(&mut self) -> Result<()> {
        self.discover_in_dir(&self.configsets_dir.clone())
    }

    fn discover_in_dir(&mut self, dir: &Path) -> Result<()> {
        if !dir.exists() {
            return Ok(());
        }

        for entry in fs::read_dir(dir)? {
            let entry = entry?;
            let path = entry.path();

            if path.is_dir() {
                // Check for configurable.yaml in this directory
                let config_path = path.join("configurable.yaml");
                if config_path.exists() {
                    if let Ok(config) = Configurable::load(&config_path) {
                        // Use relative path from configsets_dir as key
                        let rel_path = path
                            .strip_prefix(&self.configsets_dir)
                            .unwrap_or(&path)
                            .to_string_lossy()
                            .to_string();
                        self.configurables.insert(rel_path, (path.clone(), config));
                    }
                }
                // Recurse into subdirectories
                self.discover_in_dir(&path)?;
            }
        }
        Ok(())
    }

    /// Resolve dependencies using topological sort (Kahn's algorithm)
    fn resolve_dependencies(&self, task_key: &str) -> Result<Vec<String>> {
        let mut in_degree: HashMap<String, usize> = HashMap::new();
        let mut graph: HashMap<String, Vec<String>> = HashMap::new();
        let mut queue: VecDeque<String> = VecDeque::new();

        // Build the dependency graph starting from the target task
        let mut to_visit: Vec<String> = vec![task_key.to_string()];
        let mut visited: HashSet<String> = HashSet::new();

        while let Some(key) = to_visit.pop() {
            if visited.contains(&key) {
                continue;
            }
            visited.insert(key.clone());

            let (_, config) = self
                .configurables
                .get(&key)
                .with_context(|| format!("Task '{}' not found", key))?;

            in_degree.entry(key.clone()).or_insert(0);
            graph.entry(key.clone()).or_default();

            for dep in &config.dependencies {
                if !self.configurables.contains_key(dep) {
                    bail!(
                        "Dependency '{}' of task '{}' not found. Available tasks:\n{}",
                        dep,
                        key,
                        self.list_tasks()
                    );
                }

                graph.entry(dep.clone()).or_default().push(key.clone());
                *in_degree.entry(key.clone()).or_insert(0) += 1;
                to_visit.push(dep.clone());
            }
        }

        // Kahn's algorithm
        for (node, &degree) in &in_degree {
            if degree == 0 {
                queue.push_back(node.clone());
            }
        }

        let mut order: Vec<String> = Vec::new();
        while let Some(node) = queue.pop_front() {
            order.push(node.clone());
            if let Some(dependents) = graph.get(&node) {
                for dependent in dependents {
                    if let Some(degree) = in_degree.get_mut(dependent) {
                        *degree -= 1;
                        if *degree == 0 {
                            queue.push_back(dependent.clone());
                        }
                    }
                }
            }
        }

        if order.len() != in_degree.len() {
            bail!("Circular dependency detected!");
        }

        Ok(order)
    }

    /// Run a single configurable
    fn run_single(&mut self, task_key: &str, config_dir: &Path, config: &Configurable) -> Result<()> {
        let script_path = config_dir.join(&config.script);

        if !script_path.exists() {
            bail!(
                "Script not found: {} (resolved from {})",
                script_path.display(),
                config.script
            );
        }

        println!(
            "{} {} {}",
            "▶".blue(),
            "Running:".bold(),
            config.name.cyan()
        );

        if self.dry_run {
            println!("  {} {}", "Would execute:".yellow(), script_path.display());
            self.completed.insert(task_key.to_string());
            return Ok(());
        }

        let status = Command::new("bash")
            .arg(&script_path)
            .current_dir(config_dir)
            .status()
            .with_context(|| format!("Failed to execute {}", script_path.display()))?;

        if !status.success() {
            bail!(
                "Script {} failed with exit code: {:?}",
                script_path.display(),
                status.code()
            );
        }

        self.completed.insert(task_key.to_string());
        println!(
            "{} {} {}",
            "✓".green(),
            "Completed:".bold(),
            config.name.green()
        );

        Ok(())
    }

    /// Run a task with its dependencies
    fn run_task(&mut self, task_key: &str, with_deps: bool) -> Result<()> {
        let tasks = if with_deps {
            self.resolve_dependencies(task_key)?
        } else {
            vec![task_key.to_string()]
        };

        println!(
            "{} {}",
            "Tasks to run:".bold(),
            tasks
                .iter()
                .map(|t| t.cyan().to_string())
                .collect::<Vec<_>>()
                .join(" → ")
        );
        println!();

        for task in &tasks {
            // Skip if already completed in this run (handles diamond dependencies)
            if self.completed.contains(task) {
                let (_, config) = self.configurables.get(task).unwrap();
                println!(
                    "{} {} {}",
                    "⏭".yellow(),
                    "Skipping:".bold(),
                    config.name.yellow()
                );
                continue;
            }

            let (config_dir, config) = self
                .configurables
                .get(task)
                .with_context(|| format!("Task '{}' not found", task))?
                .clone();

            self.run_single(task, &config_dir, &config)?;
        }

        println!();
        println!("{}", "✓ All tasks completed successfully!".green().bold());
        Ok(())
    }

    /// Find a task by name (partial match)
    fn find_task(&self, name: &str) -> Option<String> {
        // First try exact match
        if self.configurables.contains_key(name) {
            return Some(name.to_string());
        }

        // Try matching just the last component
        for key in self.configurables.keys() {
            if key.ends_with(&format!("/{}", name)) || key == name {
                return Some(key.clone());
            }
            // Also check by configurable name
            if let Some((_, config)) = self.configurables.get(key) {
                if config.name == name {
                    return Some(key.clone());
                }
            }
        }

        None
    }

    /// List all available tasks
    fn list_tasks(&self) -> String {
        let mut tasks: Vec<_> = self.configurables.keys().collect();
        tasks.sort();
        tasks
            .iter()
            .map(|k| format!("  {}", k))
            .collect::<Vec<_>>()
            .join("\n")
    }

    fn print_tasks(&self) {
        println!("{}", "Available tasks:".bold());
        let mut tasks: Vec<_> = self.configurables.iter().collect();
        tasks.sort_by_key(|(k, _)| *k);

        for (key, (_, config)) in tasks {
            let desc = config
                .description
                .as_ref()
                .map(|d| format!(" - {}", d.dimmed()))
                .unwrap_or_default();
            let deps = if config.dependencies.is_empty() {
                String::new()
            } else {
                format!(" [deps: {}]", config.dependencies.join(", ")).dimmed().to_string()
            };
            println!("  {}{}{}", key.cyan(), desc, deps);
        }
    }
}

fn find_configsets_dir() -> Result<PathBuf> {
    // Try current directory
    let cwd = std::env::current_dir()?;
    let candidates = [
        cwd.join("configsets"),
        cwd.clone(), // Maybe we're already in configsets
        PathBuf::from("/root/Sherman/configsets"),
    ];

    for candidate in &candidates {
        if candidate.exists() && candidate.is_dir() {
            // Check if it looks like a configsets directory
            if candidate.join("shared").exists() || candidate.join("macos").exists() {
                return Ok(candidate.clone());
            }
        }
    }

    bail!("Could not find configsets directory. Use --configsets-dir to specify.")
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Determine configsets directory
    let configsets_dir = if let Some(dir) = args.configsets_dir {
        dir
    } else if let Some(ref config_file) = args.config_file {
        // If a config file is provided, use its parent as base
        config_file
            .parent()
            .map(|p| p.to_path_buf())
            .unwrap_or_else(|| PathBuf::from("."))
    } else {
        find_configsets_dir()?
    };

    let mut runner = ConfigureRunner::new(configsets_dir.clone(), args.dry_run);

    // Handle direct config file execution
    if let Some(config_file) = &args.config_file {
        let config_path = if config_file.is_absolute() {
            config_file.clone()
        } else {
            std::env::current_dir()?.join(config_file)
        };

        // If it's a directory, look for configurable.yaml inside
        let config_path = if config_path.is_dir() {
            config_path.join("configurable.yaml")
        } else {
            config_path
        };

        let config = Configurable::load(&config_path)?;
        let config_dir = config_path.parent().unwrap().to_path_buf();

        // Discover all configurables for dependency resolution
        runner.discover()?;

        // Add this config if not already discovered
        let rel_path = config_dir
            .strip_prefix(&configsets_dir)
            .unwrap_or(&config_dir)
            .to_string_lossy()
            .to_string();

        if !runner.configurables.contains_key(&rel_path) {
            runner
                .configurables
                .insert(rel_path.clone(), (config_dir, config));
        }

        return runner.run_task(&rel_path, !args.no_deps);
    }

    // Discover configurables
    runner.discover()?;

    if runner.configurables.is_empty() {
        println!(
            "{} No configurable.yaml files found in {}",
            "Warning:".yellow(),
            configsets_dir.display()
        );
        println!("Run this tool from the Sherman root directory or use --configsets-dir");
        return Ok(());
    }

    // List tasks
    if args.list {
        runner.print_tasks();
        return Ok(());
    }

    // Run specific task
    if let Some(task_name) = &args.task {
        let task_key = runner.find_task(task_name).with_context(|| {
            format!(
                "Task '{}' not found. Available tasks:\n{}",
                task_name,
                runner.list_tasks()
            )
        })?;

        return runner.run_task(&task_key, !args.no_deps);
    }

    // No action specified - show help
    println!("{}", "Usage:".bold());
    println!("  configure <path/to/configurable.yaml>  - Run a configuration file");
    println!("  configure -t <task-name>               - Run a task by name");
    println!("  configure -t <task> --no-deps          - Run task without dependencies");
    println!("  configure -l                           - List available tasks");
    println!();
    runner.print_tasks();

    Ok(())
}
