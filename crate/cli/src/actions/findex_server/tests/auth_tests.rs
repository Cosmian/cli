use cosmian_logger::log_init;
use test_findex_server::{
    AuthenticationOptions, DBConfig, DatabaseType, get_redis_url, start_test_server_with_options,
};
use tracing::{info, trace};

use crate::error::result::CosmianResult;

// let us not make other test cases fail
const PORT: u16 = 6667;

#[tokio::test]
pub(crate) async fn test_all_authentications() -> CosmianResult<()> {
    log_init(None);
    let url = get_redis_url("REDIS_URL");
    trace!("TESTS: using redis on {url}");

    let default_db_config = DBConfig {
        database_type: DatabaseType::Redis,
        clear_database: false,
        database_url: url.clone(),
    };

    // SCENARIO 1: plaintext no auth
    info!("Testing server with no auth");
    let options = AuthenticationOptions {
        use_jwt_token: false,
        use_https: false,
        use_client_cert: false,
        use_api_token: false,
        ..Default::default()
    };

    let ctx = start_test_server_with_options(default_db_config.clone(), PORT, options).await?;
    ctx.stop_server().await?;

    // SCENARIO 2: plaintext JWT token auth - successful auth with token
    info!("Testing server with JWT token auth - successful");
    let options = AuthenticationOptions {
        use_jwt_token: true,
        use_https: false,
        use_client_cert: false,
        use_api_token: false,
        ..Default::default()
    };
    // Default behavior sends valid JWT token

    let ctx = start_test_server_with_options(default_db_config.clone(), PORT, options).await?;
    ctx.stop_server().await?;

    // SCENARIO 3: tls token auth
    info!("Testing server with TLS token auth");
    let options = AuthenticationOptions {
        use_jwt_token: true,
        use_https: true,
        use_client_cert: false,
        use_api_token: false,
        ..Default::default()
    };
    // Default behavior sends valid JWT token

    let ctx = start_test_server_with_options(default_db_config.clone(), PORT, options).await?;
    ctx.stop_server().await?;

    // SCENARIO 4: Client Certificates and JWT authentication are enabled, but the user only presents a JWT token.
    info!("Testing server with both Client Certificates and JWT auth - JWT token only");
    let options = AuthenticationOptions {
        use_jwt_token: true,
        use_https: true,
        use_client_cert: true,
        use_api_token: false,
        with_no_certificate: true, // Don't send the client certificate
        ..Default::default()
    };

    let ctx = start_test_server_with_options(default_db_config.clone(), PORT, options).await?;
    ctx.stop_server().await?;

    // SCENARIO 5: Both Client Certificates and API token authentication are enabled, the user presents an API token only
    info!("Testing server with both Client Certificates and API token auth - API token only");
    let options = AuthenticationOptions {
        use_jwt_token: false,
        use_https: true,
        use_client_cert: true,
        use_api_token: true,
        with_no_certificate: true, // Don't send client certificate
        ..Default::default()
    };
    // Default behavior sends a valid API token

    let ctx = start_test_server_with_options(default_db_config.clone(), PORT, options).await?;
    ctx.stop_server().await?;

    // SCENARIO 6: Both JWT and API token authentication are enabled, user presents an API token only
    info!("Testing server with both JWT and API token auth - API token only");
    let options = AuthenticationOptions {
        use_jwt_token: true,
        use_https: false,
        use_client_cert: false,
        use_api_token: true,
        with_invalid_jwt_token: true, // Send invalid JWT token
        ..Default::default()
    };
    // Default behavior sends valid API token

    let ctx = start_test_server_with_options(default_db_config.clone(), PORT, options).await?;
    ctx.stop_server().await?;

    Ok(())
}
