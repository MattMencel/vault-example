
resource "azurerm_public_ip" "ingress_public_ip" {
  name                = "ingress_public_ip"
  location            = "${azurerm_resource_group.vaultdemo.location}"
  resource_group_name = "${azurerm_kubernetes_cluster.aks_cluster.node_resource_group}"
  allocation_method   = "Static"
  domain_name_label   = "vault-ui-${lower(random_string.label.result)}"
}

resource "tls_private_key" "key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "cert" {
  key_algorithm   = tls_private_key.key.algorithm
  private_key_pem = tls_private_key.key.private_key_pem

  subject {
    common_name  = azurerm_public_ip.ingress_public_ip.fqdn
    organization = "10th Magnitude"
  }

  dns_names             = [azurerm_public_ip.ingress_public_ip.fqdn]
  validity_period_hours = 24

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
resource "kubernetes_secret" "example" {
  metadata {
    name = "vault-ui-tls"
  }

  data = {
    "tls.crt" = "${tls_self_signed_cert.cert.cert_pem}"
    "tls.key" = "${tls_private_key.key.private_key_pem}"
  }

  type = "kubernetes.io/tls"
}

resource "helm_release" "nginx-ingress" {
  name  = "nginx-ingress"
  chart = "stable/nginx-ingress"
  wait  = false

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = "${azurerm_public_ip.ingress_public_ip.ip_address}"
  }

  set {
    name  = "rbac.create"
    value = "false"
  }
}

resource "kubernetes_ingress" "vault_ingress" {
  metadata {
    name = "vault-ui"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      #host = "vault-ui.${azurerm_kubernetes_cluster.aks_cluster.addon_profile[0].http_application_routing[0].http_application_routing_zone_name}"
      host = "${azurerm_public_ip.ingress_public_ip.fqdn}"
      http {
        path {
          backend {
            service_name = "vault-ui"
            service_port = 8200
          }

          path = "/"
        }
      }
    }

    tls {
      secret_name = "vault-ui-tls"
    }
  }
}
