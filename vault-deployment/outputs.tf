output "psql_password" {
  value = "${random_string.psql_password.result}"
}

output "chartmuseum_url" {
  value = "http://${azurerm_container_group.chartmuseum.fqdn}:8080"
}

output "vault-ui" {
  value = "vault-ui.${azurerm_kubernetes_cluster.aks_cluster.addon_profile[0].http_application_routing[0].http_application_routing_zone_name}"
}

output "vault-ui-ip" {
  value = "${kubernetes_ingress.vault_ingress.load_balancer_ingress[0].ip}"
}
