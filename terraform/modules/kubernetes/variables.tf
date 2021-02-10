variable "k8s_version" {
  description = "Kubernetes Version"
  default = "1.19.3"
}

variable "app_name" {
  description = "Application Name"  
}

variable "resource_group" {
  description = "Resource Group"
}

variable "service_principal" {
  description = "Service Principal"
}

variable "service_principal_password" {
  description = "Service Principal Password"
}

variable "key_vault" {
  description = "Application Key Vault"
}
