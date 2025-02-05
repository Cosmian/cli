use std::path::PathBuf;

use cosmian_config_utils::{location, ConfigUtils};
use cosmian_findex_cli::reexports::cosmian_findex_client::FindexClientConfig;
use cosmian_kms_cli::reexport::cosmian_kms_client::KmsClientConfig;
use serde::{Deserialize, Serialize};
use tracing::debug;

use crate::error::CosmianError;

pub const COSMIAN_CLI_CONF_ENV: &str = "COSMIAN_CLI_CONF";
pub(crate) const COSMIAN_CLI_CONF_DEFAULT_SYSTEM_PATH: &str = "/etc/cosmian/cosmian.toml";
pub(crate) const COSMIAN_CLI_CONF_PATH: &str = ".cosmian/cosmian.toml";

#[derive(Serialize, Deserialize, Eq, PartialEq, Debug, Clone)]
pub struct ClientConf {
    pub kms_config: KmsClientConfig,
    pub findex_config: Option<FindexClientConfig>,
}

impl Default for ClientConf {
    fn default() -> Self {
        Self {
            kms_config: KmsClientConfig::default(),
            findex_config: Some(FindexClientConfig::default()),
        }
    }
}

#[allow(clippy::print_stdout)]
impl ClientConf {
    /// Load the default location of the configuration file.
    ///
    /// # Errors
    /// Return an error if the configuration file is not found or if the file is
    /// not a valid toml file.
    pub fn location(conf: Option<PathBuf>) -> Result<PathBuf, CosmianError> {
        Ok(location(
            conf,
            COSMIAN_CLI_CONF_ENV,
            COSMIAN_CLI_CONF_PATH,
            COSMIAN_CLI_CONF_DEFAULT_SYSTEM_PATH,
        )?)
    }

    /// Load the configuration from a toml file.
    /// # Errors
    /// Return an error if the configuration file is not found or if the file is
    /// not a valid toml file.
    pub fn load(conf_path: Option<PathBuf>) -> Result<Self, CosmianError> {
        let conf_path_buf = Self::location(conf_path)?;
        debug!("Loading configuration from: {conf_path_buf:?}");

        Ok(Self::from_toml(conf_path_buf.to_str().ok_or_else(
            || {
                CosmianError::Default(
                    "Unable to convert the configuration path to a string".to_owned(),
                )
            },
        )?)?)
    }

    /// Save the configuration to a toml file.
    ///
    /// # Errors
    /// Return an error if the configuration file is not found or if the file is
    /// not a valid toml file.
    pub fn save(&self, conf_path: Option<PathBuf>) -> Result<(), CosmianError> {
        let conf_path_buf = Self::location(conf_path)?;
        println!("Saving configuration to: {conf_path_buf:?}");

        Ok(self.to_toml(conf_path_buf.to_str().ok_or_else(|| {
            CosmianError::Default("Unable to convert the configuration path to a string".to_owned())
        })?)?)
    }
}

impl ConfigUtils for ClientConf {}

#[cfg(test)]
mod tests {
    use std::{env, fs, path::PathBuf};

    use cosmian_config_utils::{get_default_conf_path, ConfigUtils};
    use cosmian_logger::log_init;

    use super::{ClientConf, COSMIAN_CLI_CONF_ENV};
    use crate::config::COSMIAN_CLI_CONF_PATH;

    #[test]
    pub(crate) fn test_load() {
        log_init(None);
        // valid conf
        unsafe {
            env::set_var(COSMIAN_CLI_CONF_ENV, "../../test_data/configs/cosmian.toml");
        }
        assert!(ClientConf::load(None).is_ok());

        // another valid conf
        unsafe {
            env::set_var(
                COSMIAN_CLI_CONF_ENV,
                "../../test_data/configs/cosmian_partial.toml",
            );
        }
        assert!(ClientConf::load(None).is_ok());

        // Default conf file
        unsafe {
            env::remove_var(COSMIAN_CLI_CONF_ENV);
        }
        drop(fs::remove_file(
            get_default_conf_path(COSMIAN_CLI_CONF_PATH).unwrap(),
        ));
        assert!(ClientConf::load(None).is_ok());
        assert!(get_default_conf_path(COSMIAN_CLI_CONF_PATH)
            .unwrap()
            .exists());

        // invalid conf
        unsafe {
            env::set_var(
                COSMIAN_CLI_CONF_ENV,
                "../../test_data/configs/cosmian.bad.toml",
            );
        }
        let e = ClientConf::load(None).err().unwrap().to_string();
        assert!(e.contains("missing field `server_url`"));

        // with a file
        unsafe {
            env::remove_var(COSMIAN_CLI_CONF_ENV);
        }
        let conf_path =
            ClientConf::location(Some(PathBuf::from("../../test_data/configs/cosmian.toml")))
                .unwrap();

        assert!(ClientConf::from_toml(conf_path.to_str().unwrap()).is_ok());
    }
}
