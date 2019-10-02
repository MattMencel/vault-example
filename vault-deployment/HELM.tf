
resource "kubernetes_namespace" "tiller" {
  metadata {
    name = "tiller"
  }
}

resource "null_resource" "deploy_vault_helm_to_chartmuseum" {
  triggers = {
    build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "rm -rf vault; git clone https://github.com/hashicorp/vault-helm vault; cd vault; git checkout ${var.vault-helm_release}; cd ..; helm repo add chartmuseum http://${azurerm_container_group.chartmuseum.fqdn}:8080; helm push -u user -p \"${random_string.chart_museum_pass.result}\" -f vault/ chartmuseum"
  }
}

data "helm_repository" "chartmuseum" {
  depends_on = ["null_resource.deploy_vault_helm_to_chartmuseum"]

  name = "chartmuseum"
  url  = "http://${azurerm_container_group.chartmuseum.fqdn}:8080"
}

resource "helm_release" "vault" {
  name  = "vault"
  chart = "chartmuseum/vault"
  wait  = false

  set {
    name  = "server.ha.enabled"
    value = "true"
  }

  set {
    name  = "server.ha.raft.enabled"
    value = "true"
  }
  set {
    name  = "ui.enabled"
    value = "true"
  }

  # set {
  #   name  = "ui.serviceType"
  #   value = "ClusterIP"
  # }

  set {
    name  = "server.ha.config"
    value = <<EOL
ui = true
cluster_addr = "https://POD_IP:8201"

listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}

storage "raft" {
  path = "/vault/data"
}

seal "azurekeyvault" {
  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  client_id = "${data.azurerm_client_config.current.client_id}"
  client_secret = "${var.client_secret}"
  vault_name = "${azurerm_key_vault.key_vault.name}"
  key_name = "${azurerm_key_vault_key.key_vault_key.name}"
}
EOL
  }
}
