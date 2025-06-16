$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$PSNativeCommandUseErrorActionPreference = $true # might be true by default

function BuildProject {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("debug", "release")]
        [string]$BuildType
    )

    $env:RUST_LOG = "cosmian_cli=error,cosmian_kms_server=error,test_kms_server=error"
    # Add target
    rustup target add x86_64-pc-windows-msvc

    $env:OPENSSL_DIR = "$env:VCPKG_INSTALLATION_ROOT\packages\openssl_x64-windows-static"
    Get-ChildItem -Recurse $env:OPENSSL_DIR

    # Build CLI and PKCS11 provider
    $env:FINDEX_TEST_DB = "sqlite-findex"
    if ($BuildType -eq "release")
    {
        cargo build --features "non-fips" -p cosmian_cli -p cosmian_pkcs11 --release --target x86_64-pc-windows-msvc
        cargo test  --features "non-fips" -p cosmian_cli --release --target x86_64-pc-windows-msvc -- --nocapture --skip sql --skip redis --skip google_cse --skip hsm --skip kms
    }
    else
    {
        cargo build --features "non-fips" -p cosmian_cli -p cosmian_pkcs11 --target x86_64-pc-windows-msvc
        cargo  test --features "non-fips" -p cosmian_cli --target x86_64-pc-windows-msvc -- --nocapture --skip sql --skip redis --skip google_cse --skip hsm --skip kms
    }

    # Check binaries
    Get-ChildItem target\x86_64-pc-windows-msvc\$BuildType
    Get-ChildItem target
    Get-ChildItem target\$BuildType

    # Check dynamic links
    $ErrorActionPreference = "SilentlyContinue"
    $output = & "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC\14.29.30133\bin\HostX64\x64\dumpbin.exe" /dependents target\x86_64-pc-windows-msvc\$BuildType\cosmian.exe | Select-String "libcrypto"
    if ($output) {
        throw "OpenSSL (libcrypto) found in dynamic dependencies. Error: $output"
    }
    $ErrorActionPreference = "Stop"

    exit 0
}


# Example usage:
# BuildProject -BuildType debug
# BuildProject -BuildType release
