output "key_vault" {
  description = "Appllication Key Vault"
  value = azurerm_key_vault.main
}

output "access_policy" {
  value = azurerm_key_vault_access_policy.terraform
}
