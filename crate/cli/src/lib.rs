#![deny(
    nonstandard_style,
    refining_impl_trait,
    future_incompatible,
    keyword_idents,
    let_underscore,
    unreachable_pub,
    unused,
    clippy::all,
    clippy::suspicious,
    clippy::complexity,
    clippy::perf,
    clippy::style,
    clippy::pedantic,
    clippy::cargo,
    clippy::nursery,

    // restriction lints
    clippy::map_err_ignore,
    clippy::print_stdout,
    clippy::redundant_clone
)]
#![allow(
    clippy::module_name_repetitions,
    clippy::too_many_lines,
    clippy::cargo_common_metadata,
    clippy::multiple_crate_versions,
    clippy::redundant_pub_crate
)]
pub mod actions;
pub mod commands;
pub mod config;
pub mod error;
pub mod proxy_config;

pub use commands::{Cli, CliCommands, cosmian_main};

pub mod reexport {
    pub use cosmian_findex_cli;
    pub use cosmian_kms_cli;
}

#[cfg(test)]
mod tests;
