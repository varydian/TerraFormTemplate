# Basic Terraform Setup

# Configure Terraform Backend
terraform {
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}

# Configure the Azure Provider
provider "azurerm" {
  version = "=2.39.0"
  features {}
}

# Provides Terraform Client Config Data
data "azurerm_client_config" "main" {}

# Create Azure AD Application & Service Principal
module "service_principal" {
  source = "./modules/service_principal"
  app_name = var.app_name
}

# Create Resource Group that'll contain the resources defined in this document.
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.app_name}"
  location = var.app_location
}

# Create Key Vault that will hold all Application Secrets
module "key_vault" {
  source = "./modules/key_vault"
  resource_group = azurerm_resource_group.main
  service_principal = module.service_principal.service_principal
}

# Create Kubernetes Cluster
module "k8s" {
  depends_on = [module.key_vault.access_policy]
  source = "./modules/kubernetes"
  app_name = var.app_name
  resource_group = azurerm_resource_group.main
  service_principal = module.service_principal.service_principal
  service_principal_password = module.service_principal.service_principal_password
  key_vault = module.key_vault.key_vault
}
