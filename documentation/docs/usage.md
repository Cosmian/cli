# Usage

```sh
CLI used to manage the Cosmian KMS.

Usage: cosmian [OPTIONS] <COMMAND>

Commands:
  kms            Handle KMS actions
  findex-server  Handle Findex server actions
  help           Print this message or the help of the given subcommand(s)

Options:
  -c, --conf <CONF>
          Configuration file location
      --kms-url <KMS_URL>
          The URL of the KMS
      --kms-accept-invalid-certs <KMS_ACCEPT_INVALID_CERTS>
          Allow to connect using a self-signed cert or untrusted cert chain [possible values: true, false]
      --kms-print-json
          Output the KMS JSON KMIP request and response. This is useful to understand JSON POST requests and responses required to programmatically call the KMS on the `/kmip/2_1` endpoint
      --findex-url <FINDEX_URL>
          The URL of the Findex server
      --findex-accept-invalid-certs <FINDEX_ACCEPT_INVALID_CERTS>
          Allow to connect using a self-signed cert or untrusted cert chain [possible values: true, false]
  -h, --help
          Print help (see more with '--help')
  -V, --version
          Print version
```

## KMS commands

```sh
Handle KMS actions

Usage: cosmian kms <COMMAND>

Commands:
  login           Login to the Identity Provider of the KMS server using the `OAuth2` authorization code flow.
  logout          Logout from the Identity Provider.
  access-rights   Manage the users' access rights to the cryptographic objects
  cc              Manage Covercrypt keys and policies. Rotate attributes. Encrypt and decrypt data
  certificates    Manage certificates. Create, import, destroy and revoke. Encrypt and decrypt data
  ec              Manage elliptic curve keys. Encrypt and decrypt data using ECIES
  attributes      Get/Set/Delete the KMIP object attributes
  locate          Locate cryptographic objects inside the KMS
  new-database    Initialize a new user encrypted database and return the secret (`SQLCipher` only).
  rsa             Manage RSA keys. Encrypt and decrypt data using RSA keys
  server-version  Print the version of the server
  sym             Manage symmetric keys. Encrypt and decrypt data
  google          Manage google elements. Handle key pairs and identities from Gmail API
  help            Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
```

## Findex server commands

```sh
Handle Findex server actions

Usage: cosmian findex-server <COMMAND>

Commands:
  encrypt-and-index   Encrypt entries and index the corresponding database UUIDs with the Findex. todo(manu): describe the action
  search-and-decrypt  Search keywords and decrypt the content of corresponding UUIDs.
  delete-dataset      Delete encrypted entries. (Indexes are not deleted)
  index               Index new keywords
  delete              Delete indexed keywords
  search              Findex: Search keywords.
  server-version      Print the version of the server
  login               Login to the Identity Provider of the Findex server using the `OAuth2`
                      authorization code flow.
  logout              Logout from the Identity Provider.
  permissions         Manage the users permissions to the indexes
  help                Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
```
