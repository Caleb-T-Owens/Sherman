mod commit;
mod config;
mod diff;
mod init;
mod reapply;
mod utils;

#[derive(Debug, clap::Parser)]
#[clap(name = "patc", about = "The stupid patch tracker", version = "0.0.1")]
struct Args {
    #[clap(subcommand)]
    pub cmd: Subcommand,
}

#[derive(Debug, clap::Subcommand)]
enum Subcommand {
    Init,
    Reapply,
    Diff,
    Commit {
        #[clap(long, short)]
        message: String,
    },
}

fn main() {
    let args: Args = clap::Parser::parse();

    match args.cmd {
        Subcommand::Init => init::init(),
        Subcommand::Reapply => reapply::reapply(),
        Subcommand::Diff => diff::diff(),
        Subcommand::Commit { message } => commit::commit(message),
    }
}
