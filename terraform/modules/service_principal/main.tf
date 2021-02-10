resource "random_password" "sp" {
  length = 16
  special = true

  keepers = {
    "app" = var.app_name
  }
}

# Create an application
resource "azuread_application" "main" {
  name = var.app_name
}

# Create a service principal
resource "azuread_service_principal" "main" {
  application_id = azuread_application.main.application_id
}

resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.main.id
  value                = random_password.sp.result
  end_date             = "2099-01-01T01:02:03Z"
}
