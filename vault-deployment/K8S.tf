resource "tls_private_key" "key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "cert" {
  key_algorithm   = "ECDSA"
  private_key_pem = "${tls_private_key.key.private_key_pem}"

  subject {
    common_name  = azurerm_kubernetes_cluster.aks_cluster.addon_profile[0].http_application_routing[0].http_application_routing_zone_name
    organization = "10th Magnitude"
  }

  dns_names             = [azurerm_kubernetes_cluster.aks_cluster.addon_profile[0].http_application_routing[0].http_application_routing_zone_name]
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

resource "kubernetes_ingress" "vault_ingress" {
  metadata {
    name = "vault-ui"
    annotations = {
      "kubernetes.io/ingress.class" = "addon-http-application-routing"
    }
  }

  spec {
    rule {
      host = "vault-ui.${azurerm_kubernetes_cluster.aks_cluster.addon_profile[0].http_application_routing[0].http_application_routing_zone_name}"
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


resource "kubernetes_namespace" "tiller" {
  metadata {
    name = "tiller"
  }
}
