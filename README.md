# home

<!-- markdownlint-disable MD013 -->
![CI Status](https://img.shields.io/github/actions/workflow/status/jtrrll/home/ci.yaml?branch=main&label=ci&logo=github)
![License](https://img.shields.io/github/license/jtrrll/home?label=license&logo=googledocs&logoColor=white)
<!-- markdownlint-enable MD013 -->

Home automation and infrastructure managed with [Nix](https://nixos.org/).

## Table of Contents

- [Setting Up a New Host](#setting-up-a-new-host)
- [Updating a Host](#updating-a-host)
- [Adding Secrets to a Host](#adding-secrets-to-a-host)
- [Infrastructure](#infrastructure)

## Setting Up a New Host

New hosts are provisioned with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).
This installs NixOS on a machine reachable via SSH.

```sh
nix run github:nix-community/nixos-anywhere -- --flake .#<hostname> root@<ip>
```

Disko defines the disk layout and is applied automatically.
After installation, the host reboots into NixOS with the specified configuration.

## Updating a Host

Configuration changes are applied via `nixos-rebuild switch` over SSH.

### Using the deploy script

```sh
nix run .#deploy
```

This presents an interactive list of deployments to choose from.
To deploy a specific deployment directly:

```sh
nix run .#deploy -- <deployment>
```

## Adding Secrets to a Host

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) using age encryption derived from each host's SSH host key.

### 1. Get the host's age public key

```sh
ssh-keyscan <host-ip> 2>/dev/null | grep ed25519 | ssh-to-age
```

### 2. Add the key to `.sops.yaml`

```yaml
keys:
  - &<hostname> <age-public-key>
creation_rules:
  - path_regex: modules/hosts/<hostname>_secrets\.yaml$
    key_groups:
      - age:
        - *<hostname>
```

### 3. Create or edit the encrypted secrets file

```sh
sops modules/hosts/<hostname>_secrets.yaml
```

This opens an editor where you enter secrets in plaintext.
On save, sops encrypts the file with the host's public key.
Commit the encrypted file to the repository.

### 4. Reference secrets in NixOS config

```nix
sops.secrets.my_secret.owner = "service-user";
```

The decrypted secret is available at `config.sops.secrets.my_secret.path`.

## Infrastructure

Infrastructure is managed with [terranix](https://terranix.org/) (Terraform via Nix).

### GitHub

Manages repository settings, branch protection, and secrets.

```sh
nix develop .#github-tf
tofu -chdir=.terraform/github init
tofu -chdir=.terraform/github plan
tofu -chdir=.terraform/github apply
```

To import the existing repository into state:

```sh
tofu -chdir=.terraform/github import github_repository.home home
tofu -chdir=.terraform/github import github_branch_default.main home
```
