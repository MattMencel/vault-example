provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

provider "kubernetes" {
  host                   = "${azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host}"
  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)}"
}

provider "helm" {
  namespace = "${kubernetes_namespace.tiller.metadata.0.name}"

  kubernetes {
    host                   = "${azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host}"
    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)}"
    client_key             = "${base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)}"
    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)}"
  }
}

resource "azurerm_resource_group" "vaultdemo" {
  name     = "vaultdemo"
  location = var.location
}

resource "random_string" "label" {
  length  = "4"
  special = false
}

data "azurerm_client_config" "current" {}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
