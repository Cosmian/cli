use std::path::PathBuf;

use clap::{CommandFactory, Parser, Subcommand};
use cosmian_findex_cli::{
    actions::findex_server::actions::FindexActions, reexport::cosmian_findex_client::RestClient,
};
use cosmian_kms_cli::{
    actions::kms::actions::KmsActions,
    reexport::cosmian_kms_client::{KmsClient, reexport::cosmian_http_client::ProxyParams},
};
use cosmian_logger::log_init;
use tracing::{info, trace};
use url::Url;

use crate::{
    actions::markdown::MarkdownAction, cli_error, config::ClientConfig,
    error::result::CosmianResult, proxy_config::ProxyConfig,
};

/// Updates proxy configuration for both KMS and Findex clients
///
/// # Arguments
/// * `config` - Mutable reference to the client configuration
/// * `proxy_config` - The proxy configuration from CLI arguments
///
/// # Errors
/// Returns an error if the proxy URL cannot be parsed
fn update_proxy_config(config: &mut ClientConfig, proxy_config: &ProxyConfig) -> CosmianResult<()> {
    let proxy_params: Option<ProxyParams> = if let Some(url) = &proxy_config.proxy_url {
        let exclusion_list = proxy_config
            .proxy_exclusion_list
            .clone()
            .unwrap_or_default();
        Some(ProxyParams {
            url: Url::parse(url).map_err(|e| cli_error!("Failed parsing the Proxy URL: {e}"))?,
            basic_auth_username: proxy_config.proxy_basic_auth_username.clone(),
            basic_auth_password: proxy_config.proxy_basic_auth_password.clone(),
            custom_auth_header: proxy_config.proxy_custom_auth_header.clone(),
            exclusion_list,
        })
    } else {
        None
    };

    if let Some(proxy_params) = proxy_params {
        config.kms_config.http_config.proxy_params = Some(proxy_params.clone());
        if let Some(findex_config) = config.findex_config.as_mut() {
            findex_config.http_config.proxy_params = Some(proxy_params);
        }
    }

    Ok(())
}

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
pub struct Cli {
    /// Configuration file location
    ///
    /// This is an alternative to the env variable `COSMIAN_CLI_CONF_PATH`.
    /// Takes precedence over `COSMIAN_CLI_CONF_PATH` env variable.
    #[arg(short, env = "COSMIAN_CLI_CONF_PATH", long)]
    conf_path: Option<PathBuf>,

    #[command(subcommand)]
    pub command: CliCommands,

    /// The URL of the KMS
    #[arg(long, env = "KMS_DEFAULT_URL", action)]
    pub kms_url: Option<String>,

    /// Output the KMS JSON KMIP request and response.
    /// This is useful to understand JSON POST requests and responses
    /// required to programmatically call the KMS on the `/kmip/2_1` endpoint
    #[arg(long)]
    pub kms_print_json: bool,

    /// The URL of the Findex server
    #[arg(long, env = "FINDEX_SERVER_DEFAULT_URL", action)]
    pub findex_url: Option<String>,

    /// Allow to connect using a self-signed cert or untrusted cert chain
    ///
    /// `accept_invalid_certs` is useful if the CLI needs to connect to an HTTPS
    /// KMS server running an invalid or insecure SSL certificate
    #[arg(long)]
    pub accept_invalid_certs: bool,

    #[clap(flatten)]
    pub proxy: ProxyConfig,
}

#[derive(Subcommand)]
pub enum CliCommands {
    /// Handle KMS actions
    #[command(subcommand)]
    Kms(KmsActions),
    /// Handle Findex server actions
    #[command(subcommand)]
    Findex(FindexActions),
    /// Action to auto-generate doc in Markdown format
    /// Run `cargo run --bin cosmian -- markdown
    /// documentation/docs/cli/main_commands.md`
    #[clap(hide = true)]
    Markdown(MarkdownAction),
}

/// Main function for the Cosmian CLI application.
///
/// This function initializes logging, parses command-line arguments, and
/// executes the appropriate command based on the provided arguments. It
/// supports various subcommands for interacting with the Cosmian CLI, such as login,
/// logout, locating objects, and more.
///
/// # Errors
///
/// This function will return an error if:
/// - The logging initialization fails.
/// - The command-line arguments cannot be parsed.
/// - The configuration file cannot be located or loaded.
/// - Any of the subcommands fail during their execution.
pub async fn cosmian_main() -> CosmianResult<()> {
    log_init(None);
    info!("Starting Cosmian CLI");
    let cli = Cli::parse();

    let mut config = ClientConfig::load(cli.conf_path.clone())?;

    // Handle KMS configuration
    if let Some(url) = cli.kms_url.clone() {
        config.kms_config.http_config.server_url = url;
    }
    if cli.accept_invalid_certs {
        config.kms_config.http_config.accept_invalid_certs = true;
    }
    config.kms_config.print_json = Some(cli.kms_print_json);

    // Handle Findex server configuration
    if let Some(findex_config) = config.findex_config.as_mut() {
        if let Some(url) = cli.findex_url.clone() {
            findex_config.http_config.server_url = url;
        }
        if cli.accept_invalid_certs {
            findex_config.http_config.accept_invalid_certs = true;
        }
    }

    update_proxy_config(&mut config, &cli.proxy)?;

    trace!("Configuration: {config:#?}");

    // Instantiate the KMS client
    let kms_rest_client = KmsClient::new_with_config(config.kms_config.clone())?;

    match &cli.command {
        CliCommands::Markdown(action) => {
            action.process(&Cli::command())?;
            return Ok(());
        }
        CliCommands::Kms(kms_actions) => {
            let new_kms_config = Box::pin(kms_actions.process(kms_rest_client)).await?;
            if config.kms_config != new_kms_config {
                config.kms_config = new_kms_config;
                config.save(cli.conf_path.clone())?;
            }
        }
        CliCommands::Findex(findex_actions) => {
            let findex_config = config
                .findex_config
                .as_ref()
                .ok_or_else(|| cli_error!("Missing Findex server configuration"))?;
            let findex_client = RestClient::new(findex_config.clone())?;
            let new_findex_config = findex_actions.run(findex_client, kms_rest_client).await?;
            if config.findex_config.as_ref() != Some(&new_findex_config) {
                config.findex_config = Some(new_findex_config);
                config.save(cli.conf_path.clone())?;
            }
        }
    }

    Ok(())
}
