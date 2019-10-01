resource "azurerm_key_vault" "key_vault" {
  name                        = "vault-keyvault-${random_string.label.result}"
  location                    = azurerm_resource_group.vaultdemo.location
  resource_group_name         = azurerm_resource_group.vaultdemo.name
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = "${var.tenant_id}"

  sku_name = "standard"


  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.service_principal_object_id

    key_permissions = [
      "get",
      "list",
      "create",
      "delete",
      "update",
      "wrapKey",
      "unwrapKey",
    ]
  }

}

resource "azurerm_key_vault_key" "key_vault_key" {
  name         = "autounseal"
  key_vault_id = azurerm_key_vault.key_vault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}
