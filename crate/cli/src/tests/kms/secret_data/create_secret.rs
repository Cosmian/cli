use std::{collections::HashSet, process::Command};

use assert_cmd::prelude::*;
use test_kms_server::start_default_test_kms_server;

use crate::{
    config::COSMIAN_CLI_CONF_ENV,
    error::{CosmianError, result::CosmianResult},
    tests::{
        PROG_NAME,
        kms::{
            KMS_SUBCOMMAND,
            utils::{extract_uids::extract_unique_identifier, recover_cmd_logs},
        },
        save_kms_cli_config,
    },
};

#[derive(Default)]
pub(crate) struct SecretDataOptions {
    pub(crate) tags: HashSet<String>,
    pub(crate) sensitive: bool,
    pub(crate) key_id: Option<String>,
}

pub(crate) fn create_secret_data(
    cli_conf_path: &str,
    options: &SecretDataOptions,
) -> CosmianResult<String> {
    let mut cmd = Command::cargo_bin(PROG_NAME)?;
    cmd.env(COSMIAN_CLI_CONF_ENV, cli_conf_path);

    let mut args = vec!["secret-data", "create"];

    // add tags
    for tag in &options.tags {
        args.push("--tag");
        args.push(tag);
    }
    if options.sensitive {
        args.push("--sensitive");
    }
    if let Some(key_id) = options.key_id.as_ref() {
        args.push(key_id);
    }
    cmd.arg(KMS_SUBCOMMAND).args(args);

    let output = recover_cmd_logs(&mut cmd);
    if output.status.success() {
        let secret_data_output = std::str::from_utf8(&output.stdout)?;
        assert!(secret_data_output.contains("The secret data was successfully generated."));
        let secret_data_id = extract_unique_identifier(secret_data_output)
            .ok_or_else(|| CosmianError::Default("failed extracting the private key".to_owned()))?
            .to_owned();
        return Ok(secret_data_id)
    }

    Err(CosmianError::Default(
        std::str::from_utf8(&output.stderr)?.to_owned(),
    ))
}

#[tokio::test]
pub(crate) async fn test_secret_data() -> CosmianResult<()> {
    // from specs
    let ctx = start_default_test_kms_server().await;
    let (owner_client_conf_path, _) = save_kms_cli_config(ctx);
    create_secret_data(
        &owner_client_conf_path,
        &SecretDataOptions {
            tags: HashSet::from_iter(vec!["tag1".to_owned(), "tag2".to_owned()]),
            ..Default::default()
        },
    )?;

    let created_id = create_secret_data(
        &owner_client_conf_path,
        &SecretDataOptions {
            key_id: Some("secret_id".to_owned()),
            tags: HashSet::from_iter(vec!["tag1".to_owned(), "tag2".to_owned()]),
            ..Default::default()
        },
    )?;
    assert_eq!(created_id, "secret_id".to_owned());
    Ok(())
}
