variable "subscription_id" {
}

variable "client_id" {
}

variable "client_secret" {
}

variable "tenant_id" {
}

# DEFAULT VARS
variable "location" {
  default = "eastus"
}

# AKS
variable "aks_cluster_name" {
  default = "aks_vault_demo"
}

variable "dns_prefix" {
  default = "vaultdemo"
}

variable "kubernetes_version" {
  default = "1.14.6"
}

variable "vm_username" {
  default = "aks_user"
}

variable "node_count" {
  default = "3"
}

variable "vm_size" {
  default = "Standard_B2s"
}

# VAULT VARS
variable "vault-helm_release" {
  default = "raft"
}
