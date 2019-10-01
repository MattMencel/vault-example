provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables VAULT_TOKEN and VAULT_ADDRESS.
  #
  # VAULT TOKEN it the initial root token from when Vault was initialaized.
  # VAULT_ADDRESS is the vault-ui output from running terrform in the terraform-deployment folder

  # DO NOT USE THIS IN PRODUCTION!
  skip_tls_verify = true
}

