# Creates a random 
resource "random_string" "kv" {
  length  = 20
  special = false

  keepers = {
    "app" = var.resource_group.id
  }
}

# Provides Terraform Client Config Data
data "azurerm_client_config" "main" {}

resource "azurerm_key_vault" "main" {
  name                        = "kv-${random_string.kv.result}"
  location                    = var.resource_group.location
  resource_group_name         = var.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.main.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"
}

# Make Sure Terraform can access the Key Vault
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id        = azurerm_key_vault.main.id
  tenant_id           = data.azurerm_client_config.main.tenant_id
  object_id           = data.azurerm_client_config.main.object_id
  secret_permissions  = ["backup", "delete", "get", "list", "purge", "recover", "restore", "set"]
}

# Make Sure Application Service Principal can access the Key Vault
resource "azurerm_key_vault_access_policy" "service_principal" {
  key_vault_id        = azurerm_key_vault.main.id
  tenant_id           = data.azurerm_client_config.main.tenant_id
  object_id           = var.service_principal.object_id
  secret_permissions  = ["get"]
}
