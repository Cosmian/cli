use std::{ops::Deref, path::PathBuf};

use cosmian_findex_cli::{
    actions::findex_server::findex::{
        insert_or_delete::InsertOrDeleteAction, parameters::FindexParameters, search::SearchAction,
    },
    reexport::cosmian_findex_client::{
        FindexRestClient, KmsEncryptionLayer, RestClient, RestClientConfig,
    },
};
use cosmian_kms_cli::reexport::cosmian_kms_client::KmsClient;
use uuid::Uuid;

use super::basic::findex_number_of_threads;
use crate::{error::result::CosmianResult, tests::findex_server::search_options::SearchOptions};

pub(crate) const SMALL_DATASET: &str = "../../test_data/datasets/smallpop.csv";
pub(crate) const HUGE_DATASET: &str = "../../test_data/datasets/business-employment.csv";

pub(crate) async fn insert_search_delete(
    findex_parameters: &FindexParameters,
    config: &RestClientConfig,
    search_options: SearchOptions,
    kms_client: KmsClient,
) -> CosmianResult<()> {
    let rest_client = RestClient::new(config.clone())?;

    // Index the dataset
    InsertOrDeleteAction {
        findex_parameters: findex_parameters.clone(),
        csv: PathBuf::from(&search_options.dataset_path),
    }
    .insert(rest_client.clone(), kms_client.clone())
    .await?;

    // Ensure searching returns the expected results
    let search_results = SearchAction {
        findex_parameters: findex_parameters.clone(),
        keyword: search_options.keywords.clone(),
    }
    .run(rest_client.clone(), kms_client.clone())
    .await?;
    assert_eq!(
        search_options.expected_results,
        search_results.deref().clone()
    );

    // Delete the dataset
    InsertOrDeleteAction {
        findex_parameters: findex_parameters.clone(),
        csv: PathBuf::from(search_options.dataset_path),
    }
    .delete(rest_client.clone(), kms_client.clone())
    .await?;

    // Ensure no results are returned after deletion
    let search_results = SearchAction {
        findex_parameters: findex_parameters.clone(),
        keyword: search_options.keywords,
    }
    .run(rest_client.clone(), kms_client)
    .await?;
    assert!(search_results.is_empty());

    Ok(())
}

pub(crate) async fn create_encryption_layer<const WORD_LENGTH: usize>(
    kms_client: KmsClient,
    rest_client: RestClient,
) -> CosmianResult<KmsEncryptionLayer<WORD_LENGTH, FindexRestClient<WORD_LENGTH>>> {
    let findex_parameters = FindexParameters::new(
        Uuid::new_v4(),
        kms_client.clone(),
        true,
        findex_number_of_threads(),
    )
    .await?;

    let encryption_layer = KmsEncryptionLayer::<WORD_LENGTH, _>::new(
        kms_client.clone(),
        findex_parameters.hmac_key_id.unwrap(),
        findex_parameters.aes_xts_key_id.unwrap(),
        FindexRestClient::<WORD_LENGTH>::new(rest_client, findex_parameters.index_id),
    );
    Ok(encryption_layer)
}
