use std::io::Write;

struct Er<T: std::error::Error> {
    inner: Box<T>,
}

impl<T: std::error::Error> std::fmt::Debug for Er<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        std::fmt::Debug::fmt(self.inner.as_ref(), f)
    }
}

impl<T: std::error::Error> From<T> for Er<T> {
    fn from(value: T) -> Self {
        Self {
            inner: Box::new(value),
        }
    }
}

const HELP: &str = "You want some help?";

fn main() -> Result<(), Er<std::io::Error>> {
    let mut stdout = std::io::stdout();
    let stdin = std::io::stdin();

    write!(stdout, "> ")?;
    stdout.flush()?;

    for line in stdin.lines() {
        handle_line(&line?);
        write!(stdout, "> ")?;
        stdout.flush()?;
    }

    Ok(())
}

fn handle_line(line: &str) {
    let args = line.split_whitespace().collect::<Vec<_>>();

    let Some(subcommand) = args.first() else {
        println!("A subcommand must be provided.");
        return;
    };

    if ["h", "help"].contains(subcommand) {
        println!("{HELP}");
        return;
    }
    if ["q", "quit"].contains(subcommand) {
        println!("Bye bye");
        std::process::exit(0);
    }

    println!("Subcommand {subcommand} is not recognised. Try `h` for help.")
}
