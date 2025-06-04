# Cosmian Command Line Interface (CLI)

Cosmian CLI is the Command Line Interface to drive [KMS](https://github.com/Cosmian/kms) and [Findex server](https://github.com/Cosmian/findex-server).

Cosmian CLI provides a powerful interface to manage and secure your cryptographic keys and secrets using the [Cosmian Key Management System KMS](https://github.com/Cosmian/kms).
The KMS offers a high-performance, scalable solution with unique features such as confidential execution in zero-trust environments, compliance with KMIP 2.1, and support for various cryptographic algorithms and protocols.

Additionally, the CLI facilitates interaction with the [Findex server](https://github.com/Cosmian/findex-server), which implements Searchable Symmetric Encryption (SSE) via the [Findex protocol](https://github.com/Cosmian/findex). This allows for secure and efficient search operations over encrypted data, ensuring that sensitive information remains protected even during search queries.

By leveraging Cosmian CLI, users can seamlessly integrate advanced cryptographic functionalities and secure search capabilities into their applications, enhancing data security and privacy.

!!! important
    A Web UI version of the CLI is also available when installing the KMS server.

- [Cosmian Command Line Interface (CLI)](#cosmian-command-line-interface-cli)
  - [Version correspondence](#version-correspondence)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Usage](#usage)

!!! info "Download cosmian"

    Please download the latest versions for your Operating System from
    the [Cosmian public packages repository](https://package.cosmian.com/cli/0.5.0/)
    See below for installation instructions.

## Version correspondence

!!! warning
    The versions of the CLI, KMS, and Findex server must be compatible.
    The following table shows the compatibility between the versions:

| CLI version | KMS version      | Findex server version |
| ----------- | ---------------- | --------------------- |
| 0.1.*       | 4.20.\*, 4.21.\* | 0.1.0                 |
| 0.2.0       | 4.22.*           | 0.2.0                 |
| 0.3.0       | 4.23.*           | 0.3.0                 |
| 0.3.1       | 4.24.*           | 0.3.0                 |
| 0.4.0       | 5.0.*            | 0.3.0                 |
| 0.4.1       | 5.1.*            | 0.3.0                 |

## Installation

<!-- Warning: this doc is merged with `mkdocs merge` in the repository `public_documentation`. -->
<!-- To test locally, test with path `installation.md` -->
{!../cli/documentation/docs/installation.md!}

## Configuration

To communicate with KMS and Findex server, the clients `cosmian` expect the same configuration file. Please read the [configuration](./configuration.md) section.

## Usage

<!-- Warning: this doc is merged with `mkdocs merge` in the repository `public_documentation`. -->
<!-- To test locally, test with path `usage.md` -->
{!../cli/documentation/docs/usage.md!}
