use std::process::Command;

use assert_cmd::prelude::*;
use cosmian_logger::log_init;
use test_kms_server::start_default_test_kms_server;

use super::KMS_SUBCOMMAND;
use crate::{
    config::COSMIAN_CLI_CONF_ENV,
    error::{CosmianError, result::CosmianResult},
    tests::{PROG_NAME, kms::utils::recover_cmd_logs, save_kms_cli_config},
};

const SUB_COMMAND: &str = "server-version";

/// Request server-version
pub(crate) fn server_version(cli_conf_path: &str) -> CosmianResult<String> {
    let mut cmd = Command::cargo_bin(PROG_NAME)?;
    cmd.env(COSMIAN_CLI_CONF_ENV, cli_conf_path);

    let args = vec![
        "--kms-url".to_owned(),
        std::env::var("KMS_URL").unwrap_or_else(|_| "http://host.docker.internal:9998".to_owned()),
        "--proxy-url".to_owned(),
        "http://localhost:8181".to_owned(),
        "--proxy-basic-auth-username".to_owned(),
        "myuser".to_owned(),
        "--proxy-basic-auth-password".to_owned(),
        "mypwd".to_owned(),
    ];

    cmd.args(args).arg(KMS_SUBCOMMAND).arg(SUB_COMMAND);

    let output = recover_cmd_logs(&mut cmd);
    if output.status.success() {
        let output = std::str::from_utf8(&output.stdout)?;
        return Ok(output.to_string())
    }

    Err(CosmianError::Default(
        std::str::from_utf8(&output.stderr)?.to_owned(),
    ))
}

#[tokio::test]
pub(crate) async fn test_server_version_using_forward_proxy() -> CosmianResult<()> {
    log_init(None);
    let ctx = start_default_test_kms_server().await;
    let (owner_client_conf_path, _) = save_kms_cli_config(ctx);

    server_version(&owner_client_conf_path)?;

    Ok(())
}
