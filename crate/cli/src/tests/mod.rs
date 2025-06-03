use std::path::Path;

use cosmian_config_utils::ConfigUtils;
use cosmian_kms_cli::reexport::test_kms_server::TestsContext;

use crate::config::ClientConfig;

pub(crate) mod findex_server;
pub(crate) mod kms;

pub(crate) const PROG_NAME: &str = "cosmian";

pub(crate) fn save_kms_cli_config(kms_ctx: &TestsContext) -> (String, String) {
    let owner_file_path = format!("/tmp/owner_{}.toml", kms_ctx.server_port);
    if !Path::new(&owner_file_path).exists() {
        let conf = ClientConfig {
            kms_config: kms_ctx.owner_client_config.clone(),
            findex_config: None,
        };
        conf.to_toml(&owner_file_path)
            .expect("Failed to save owner test config");
    }

    let user_file_path = format!("/tmp/user_{}.toml", kms_ctx.server_port);
    if !Path::new(&user_file_path).exists() {
        let conf = ClientConfig {
            kms_config: kms_ctx.user_client_config.clone(),
            findex_config: None,
        };
        conf.to_toml(&user_file_path)
            .expect("Failed to save user test config");
    }

    (owner_file_path, user_file_path)
}
