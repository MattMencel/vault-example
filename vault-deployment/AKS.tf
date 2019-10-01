resource "azurerm_log_analytics_workspace" "aks_metrics" {
  name                = "aks-metrics"
  location            = "${azurerm_resource_group.vaultdemo.location}"
  resource_group_name = "${azurerm_resource_group.vaultdemo.name}"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.vaultdemo.location
  resource_group_name = azurerm_resource_group.vaultdemo.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  linux_profile {
    admin_username = var.vm_username

    ssh_key {
      key_data = tls_private_key.ssh_key.public_key_openssh
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = var.node_count
    vm_size         = var.vm_size
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }



  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_metrics.id
    }
  }
}

