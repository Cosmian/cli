use clap::CommandFactory;
use cosmian_cli::{Cli, cosmian_main, error::CosmianError};

pub async fn gui_main() -> Result<(), CosmianError> {
    let args = std::env::args().collect::<Vec<_>>();
    if args.len() < 2 {
        let cmd = Cli::command().name("Cosmian GUI");
        klask::run_app(cmd, klask::Settings::default(), |_| {});
        return Ok(());
    }

    cosmian_main().await
}
