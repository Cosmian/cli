#![allow(clippy::print_stdout)]
//! These tests are gated behind the HSM feature flag. They require a running KMS-HSM server.
//! Configure the client file at the location indicated by `KSM_HSM_CLIENT_CONF` with the appropriate content
//! then run the tests with the following command:
//! ```bash
//!  cargo test --color=always --features hsm --lib tests::hsm::test_all_hsm_cli
//! ```

use cosmian_kms_cli::reexport::test_kms_server::start_default_test_kms_server_with_utimaco_hsm;
use encrypt_decrypt::test_aes_gcm;
use revoke_destroy::test_revoke_symmetric_key;
use wrap_with_hsm_key::test_wrap_with_aes_gcm;
#[cfg(not(feature = "fips"))]
use wrap_with_hsm_key::{test_unwrap_on_export, test_wrap_with_rsa_oaep};

use crate::error::result::CosmianResult;
#[cfg(not(feature = "fips"))]
use crate::tests::kms::hsm::encrypt_decrypt::{test_rsa_pkcs_oaep, test_rsa_pkcs_v15};

mod encrypt_decrypt;
mod revoke_destroy;
mod wrap_with_hsm_key;

#[tokio::test]
async fn test_all_hsm_cli() -> CosmianResult<()> {
    let ctx = start_default_test_kms_server_with_utimaco_hsm().await;
    test_aes_gcm(ctx)?;
    test_wrap_with_aes_gcm(ctx)?;
    test_revoke_symmetric_key(ctx)?;
    #[cfg(not(feature = "fips"))]
    test_rsa_pkcs_oaep(ctx)?;
    #[cfg(not(feature = "fips"))]
    test_rsa_pkcs_v15(ctx)?;
    #[cfg(not(feature = "fips"))]
    test_unwrap_on_export(ctx)?;
    #[cfg(not(feature = "fips"))]
    test_wrap_with_rsa_oaep(ctx)?;
    Ok(())
}
