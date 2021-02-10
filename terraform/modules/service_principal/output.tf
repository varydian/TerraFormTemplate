output "service_principal" {
  description = "Service Principal"
  value = azuread_service_principal.main
}

output "service_principal_password" {
  description = "Service Principal Password"
  value = random_password.sp.result
}
