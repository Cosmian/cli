# Cosmian CLI

Cosmian CLI is a Rust-based Command Line Interface that manages KMS (Key Management System) and Findex server operations. It provides cryptographic key management and searchable symmetric encryption capabilities.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Environment Setup
- Install system dependencies:
  ```bash
  sudo apt-get update && sudo apt-get install -y libssl-dev pkg-config docker.io docker-compose-plugin
  ```
- Set required environment variables:
  ```bash
  export OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu
  export OPENSSL_INCLUDE_DIR=/usr/include/openssl
  export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig
  ```

### Repository Initialization
- Initialize git submodules (REQUIRED for builds):
  ```bash
  git submodule update --init --recursive
  ```
  - Takes ~30 seconds to complete
  - Downloads KMS, Findex server, test data, and reusable scripts

### Building the CLI
- Development build (recommended for testing changes):
  ```bash
  cargo check --features non-fips -p cosmian_cli
  ```
  - Takes ~1 minute. NEVER CANCEL. Set timeout to 120+ seconds.
  
- Release build:
  ```bash
  cargo build --release --features non-fips -p cosmian_cli
  ```
  - Takes ~8-10 minutes. NEVER CANCEL. Set timeout to 900+ seconds.
  - Binary available at `./target/release/cosmian`

### Testing
- Start Docker services for integration tests:
  ```bash
  docker compose up -d
  ```
  - Takes ~3 seconds to start Redis container
  
- Run tests:
  ```bash
  export RUST_LOG="cosmian_cli=error,cosmian_findex_client=debug,cosmian_kms_client=debug"
  cargo test --release --features non-fips -p cosmian_cli -- --nocapture
  ```
  - Takes ~15-20 minutes to complete. NEVER CANCEL. Set timeout to 1800+ seconds.
  - Includes downloading additional test dependencies (~5 minutes)
  - Compilation of test binaries (~10 minutes)
  - Test execution (~5 minutes)

### Code Quality and Linting
- Format code:
  ```bash
  cargo fmt
  ```
- Run clippy linter:
  ```bash
  cargo clippy --features non-fips
  ```
- ALWAYS run formatting and linting before committing changes or CI will fail

## Validation Scenarios

### Basic CLI Functionality
After making changes, ALWAYS validate:
1. CLI help works:
   ```bash
   ./target/release/cosmian --help
   ```
2. KMS subcommand works:
   ```bash
   ./target/release/cosmian kms --help
   ```
3. Findex subcommand works:
   ```bash
   ./target/release/cosmian findex --help
   ```

### End-to-End Testing
When making significant changes, test a complete workflow:
1. Start Docker services: `docker compose up -d`
2. Run the integration test script:
   ```bash
   bash .github/scripts/cosmian_tests.sh
   ```
   - Takes ~30 seconds to complete
   - Tests key creation, encryption/decryption, and search functionality

## Important File Locations

### Source Code Structure
- Main CLI source: `crate/cli/src/`
- KMS integration: `kms/` (git submodule)
- Findex integration: `findex-server/` (git submodule)
- Test data: `test_data/` (git submodule)
- CI/CD scripts: `.github/scripts/`

### Configuration Files
- Cargo workspace: `Cargo.toml`
- Rust toolchain: `rust-toolchain.toml` (nightly-2025-03-31)
- Formatting config: `.rustfmt.toml`
- Docker services: `docker-compose.yml`

### Key Build Scripts
- Main build script: `.github/scripts/cargo_build.sh`
- Test script: `.github/scripts/cosmian_tests.sh`
- Release script: `.github/scripts/release.sh`

## Common Issues and Workarounds

### OpenSSL Build Issues
- If OpenSSL linking fails, ensure environment variables are set:
  ```bash
  export OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu
  export OPENSSL_INCLUDE_DIR=/usr/include/openssl
  ```
- The repository expects OpenSSL v3.2.0 but system OpenSSL 3.0.13+ works fine

### Network Connectivity Issues
- If external OpenSSL download fails (package.cosmian.com), use system OpenSSL
- Some test dependencies may timeout - increase timeout values accordingly
- Docker registry access required for Redis container

### Build Performance
- First build downloads many dependencies (~5 minutes)
- Subsequent builds are faster due to caching
- Use `cargo check` for quick validation instead of full builds
- Release builds are significantly slower than debug builds

## Critical Timing Expectations

**NEVER CANCEL these long-running operations:**
- `git submodule update --init --recursive`: 30 seconds
- `cargo build --release`: 8-10 minutes  
- `cargo test`: 15-20 minutes
- `docker compose up -d`: 3 seconds

Always set appropriate timeouts (at least 2x expected time) and wait for completion.

## Repository Context

This is a Rust workspace with multiple crates:
- Main CLI crate (`cosmian_cli`)
- PKCS11 provider and module crates
- Integrated KMS and Findex server submodules
- Comprehensive test suites with Docker-based services

The CLI supports both KMS operations (key management, encryption/decryption) and Findex operations (searchable symmetric encryption). All operations can work with local test servers or remote production instances.