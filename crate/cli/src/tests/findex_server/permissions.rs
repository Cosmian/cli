use cosmian_findex_cli::{
    actions::findex_server::permissions::{
        CreateIndex, ListPermissions, RevokePermission, SetPermission,
    },
    reexport::{cosmian_findex_client::RestClient, cosmian_findex_structs::Permission},
};
use uuid::Uuid;

use crate::error::result::CosmianResult;

pub(crate) async fn create_index_id(rest_client: RestClient) -> CosmianResult<Uuid> {
    Ok(CreateIndex.run(rest_client).await?)
}

pub(crate) async fn list_permissions(
    rest_client: RestClient,
    user: String,
) -> CosmianResult<String> {
    Ok(ListPermissions { user }.run(rest_client).await?)
}

pub(crate) async fn set_permission(
    rest_client: RestClient,
    user: String,
    index_id: Uuid,
    permission: Permission,
) -> CosmianResult<String> {
    Ok(SetPermission {
        user,
        index_id,
        permission,
    }
    .run(rest_client)
    .await?)
}

pub(crate) async fn revoke_permission(
    rest_client: RestClient,
    user: String,
    index_id: Uuid,
) -> CosmianResult<String> {
    Ok(RevokePermission { user, index_id }.run(rest_client).await?)
}
