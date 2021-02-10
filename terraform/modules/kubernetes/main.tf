resource "azurerm_kubernetes_cluster" "main" {
  kubernetes_version  = var.k8s_version
  name                = "aks-${var.app_name}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  node_resource_group = "${var.resource_group.name}-k8s"
  dns_prefix          = var.app_name

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "Standard"
  }

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_B2ms"
  }

  service_principal {
    client_id     = var.service_principal.application_id
    client_secret = var.service_principal_password
  }

  role_based_access_control {
    enabled = true
  }
}

resource "azurerm_key_vault_secret" "kubeconfig" {
  key_vault_id = var.key_vault.id
  name = "kubeconfig"
  value = azurerm_kubernetes_cluster.main.kube_config_raw
}
