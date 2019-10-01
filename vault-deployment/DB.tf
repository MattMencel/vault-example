resource "random_string" "psql_password" {
  length = 12
}

resource "azurerm_postgresql_server" "psql_server" {
  name                = "psql-server-${lower(random_string.label.result)}"
  location            = "${azurerm_resource_group.vaultdemo.location}"
  resource_group_name = "${azurerm_resource_group.vaultdemo.name}"

  sku {
    name     = "B_Gen5_1"
    capacity = 1
    tier     = "Basic"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "psqladmin"
  administrator_login_password = "${random_string.psql_password.result}"
  version                      = "9.5"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_postgresql_database" "exampledb" {
  name                = "exampledb"
  resource_group_name = "${azurerm_resource_group.vaultdemo.name}"
  server_name         = "${azurerm_postgresql_server.psql_server.name}"
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_postgresql_firewall_rule" "allow_vault" {
  name                = "vault"
  resource_group_name = "${azurerm_resource_group.vaultdemo.name}"
  server_name         = "${azurerm_postgresql_server.psql_server.name}"
  start_ip_address    = "${kubernetes_ingress.vault_ingress.load_balancer_ingress[0].ip}"
  end_ip_address      = "${kubernetes_ingress.vault_ingress.load_balancer_ingress[0].ip}"
}

resource "azurerm_postgresql_firewall_rule" "my_ip" {
  name                = "my_ip"
  resource_group_name = "${azurerm_resource_group.vaultdemo.name}"
  server_name         = "${azurerm_postgresql_server.psql_server.name}"
  start_ip_address    = "${chomp(data.http.myip.body)}"
  end_ip_address      = "${chomp(data.http.myip.body)}"
}
