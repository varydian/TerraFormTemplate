output "sp_application_id" {
  description = "Service Principal Application ID"
  value = module.service_principal.service_principal.application_id
  sensitive = true
}

output "sp_client_secret" {
  description = "Service Principal Application Secret"
  value = module.service_principal.service_principal_password
  sensitive = true
}

output "sp_tenant_id" {
  description = "Service Principal Tenant ID"
  value = data.azurerm_client_config.main.tenant_id
  sensitive = true
}

output "key_vault_name" {
  description = "value"
  value = module.key_vault.key_vault.name
}
