# Cosmian CLI

Cosmian CLI is a Rust-based Command Line Interface that manages KMS (Key Management System) and Findex server operations. It provides cryptographic key management and searchable symmetric encryption capabilities.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Environment Setup
- Install system dependencies with OpenSSL 3.2.0:
  ```bash
  sudo apt-get update && sudo apt-get install -y libssl-dev pkg-config docker.io docker-compose-plugin
  # Ensure OpenSSL 3.2.0 is installed for optimal compatibility
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
  
- Run full test suite:
  ```bash
  export RUST_LOG="cosmian_cli=error,cosmian_findex_client=debug,cosmian_kms_client=debug"
  cargo test --release --features non-fips -p cosmian_cli -- --nocapture
  ```
  - Takes ~11-15 minutes to complete. NEVER CANCEL. Set timeout to 1200+ seconds.
  - Includes downloading additional test dependencies (~2 minutes)
  - Compilation of test binaries (~4 minutes)
  - Test execution (~5-9 minutes)
  - Note: Some tests may fail in restricted environments (HSM, auth tests) - this is expected

### Code Quality and Linting
- Install clippy (if not available):
  ```bash
  rustup component add clippy
  ```
- Format code:
  ```bash
  cargo fmt
  ```
  - Takes <1 second
- Run clippy linter:
  ```bash
  cargo clippy --features non-fips -- -D warnings
  ```
  - Takes ~17 seconds for initial run
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
When making significant changes, test complete workflows:

1. **KMS Workflow (requires running KMS server):**
   ```bash
   # Start KMS server
   docker run -d -p 9998:9998 --name kms ghcr.io/cosmian/kms
   
   # Test key creation, encryption, decryption
   ./target/release/cosmian --kms-url http://localhost:9998 kms sym keys create --number-of-bits 256 --algorithm aes --tag test-key
   echo "Test data" > /tmp/test.txt
   ./target/release/cosmian --kms-url http://localhost:9998 kms sym encrypt --tag test-key --output-file /tmp/test.enc /tmp/test.txt
   ./target/release/cosmian --kms-url http://localhost:9998 kms sym decrypt --tag test-key --output-file /tmp/test_dec.txt /tmp/test.enc
   cat /tmp/test_dec.txt  # Should show "Test data"
   ```

2. **Findex Workflow (requires running Findex server):**
   ```bash
   # Start Findex server
   docker run -d -p 6668:6668 --name findex ghcr.io/cosmian/findex-server
   
   # Test index creation (may need time for server startup)
   ./target/release/cosmian --findex-url http://localhost:6668 findex permissions create
   ```

**Note**: The integration test script `.github/scripts/cosmian_tests.sh` uses incorrect port configurations and will fail. Use the manual workflows above instead.

## Common Commands Reference

### Quick Development Cycle
```bash
# 1. Initialize repository (first time only)
git submodule update --init --recursive

# 2. Set up environment
export OPENSSL_LIB_DIR=/usr/lib/x86_64-linux-gnu
export OPENSSL_INCLUDE_DIR=/usr/include/openssl
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig

# 3. Quick check during development
cargo check --features non-fips -p cosmian_cli

# 4. Build for testing
cargo build --release --features non-fips -p cosmian_cli

# 5. Run specific tests
cargo test --features non-fips -p cosmian_cli [test_name]

# 6. Format and lint before committing
cargo fmt && cargo clippy --features non-fips -- -D warnings
```

### Docker Services Management
```bash
# Start all services
docker compose up -d

# Start KMS only
docker run -d -p 9998:9998 --name kms ghcr.io/cosmian/kms

# Start Findex only  
docker run -d -p 6668:6668 --name findex ghcr.io/cosmian/findex-server

# Check service status
docker ps

# View logs
docker logs kms
docker logs findex

# Stop and clean up
docker stop kms findex cli-redis-1
docker rm kms findex cli-redis-1
docker compose down
```

### Build Troubleshooting
```bash
# Clean build cache if encountering issues
cargo clean

# Update toolchain if needed  
rustup update

# Check current toolchain
rustup show

# Install missing components
rustup component add clippy rustfmt
```

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
- The repository requires OpenSSL v3.2.0 for optimal compatibility

### Network Connectivity Issues
- If external OpenSSL download fails (package.cosmian.com), ensure OpenSSL 3.2.0 is available
- Some test dependencies may timeout - increase timeout values accordingly
- Docker registry access required for Redis container
- Integration test script has wrong port configurations (19998/16668 vs 9998/6668)

### Build Performance
- First build downloads many dependencies (~2 minutes)
- Subsequent builds are faster due to caching
- Use `cargo check` for quick validation instead of full builds
- Release builds are significantly slower than debug builds

### Test Environment Limitations
- Some tests expect HSM hardware/software that may not be available
- Authentication tests may fail without proper server configuration
- Certificate tests may fail in restricted environments
- These failures are expected in sandboxed/CI environments

## Critical Timing Expectations

**NEVER CANCEL these long-running operations:**
- `git submodule update --init --recursive`: 30 seconds
- `cargo build --release`: 8-10 minutes  
- `cargo test`: 11-15 minutes
- `cargo clippy`: 17 seconds (first run)
- `docker compose up -d`: 3 seconds

Always set appropriate timeouts (at least 2x expected time) and wait for completion.

## Repository Context

This is a Rust workspace with multiple crates:
- Main CLI crate (`cosmian_cli`)
- PKCS11 provider and module crates
- Integrated KMS and Findex server submodules
- Comprehensive test suites with Docker-based services

The CLI supports both KMS operations (key management, encryption/decryption) and Findex operations (searchable symmetric encryption). All operations can work with local test servers or remote production instances.

### Architecture Overview
- **Workspace Structure**: Multi-crate Rust workspace using Cargo workspaces
- **Git Submodules**: KMS, Findex server, test data, and reusable scripts
- **Docker Integration**: Redis for tests, KMS/Findex servers for integration testing
- **Cross-platform**: Supports Linux, macOS, and Windows (requires OpenSSL 3.2.0 setup)
- **CI/CD**: GitHub Actions with comprehensive build, test, and release pipelines

### Development Workflow
1. Clone repository and initialize submodules
2. Set up OpenSSL 3.2.0 environment variables
3. Use `cargo check` for rapid iteration
4. Use `cargo test` for comprehensive validation
5. Use manual end-to-end testing for critical paths
6. Always format and lint before committing
7. Validate CLI functionality with real servers when possible

### Production Considerations
- The CLI is designed to work with production KMS and Findex deployments
- Security features include certificate validation, authentication, and encrypted communications
- Performance optimizations are present in release builds
- Configuration can be done via files, environment variables, or command-line arguments