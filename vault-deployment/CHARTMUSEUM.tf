
resource "azurerm_storage_account" "vaultdemo" {
  name                     = "vaultdemo"
  resource_group_name      = "${azurerm_resource_group.vaultdemo.name}"
  location                 = "${azurerm_resource_group.vaultdemo.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "charts" {
  name                 = "charts"
  storage_account_name = "${azurerm_storage_account.vaultdemo.name}"
  quota                = 50
}

resource "random_string" "chart_museum_pass" {
  length = 16
}

resource "azurerm_container_group" "chartmuseum" {
  name                = "chartmuseum"
  location            = "${azurerm_resource_group.vaultdemo.location}"
  resource_group_name = "${azurerm_resource_group.vaultdemo.name}"
  ip_address_type     = "public"
  dns_name_label      = "chartmuseum-${random_string.label.result}"
  os_type             = "Linux"

  container {
    name   = "chartmuseum"
    image  = "chartmuseum/chartmuseum"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = {
      DEBUG                 = "1",
      BASIC_AUTH_USER       = "user",
      BASIC_AUTH_PASS       = "${random_string.chart_museum_pass.result}"
      AUTH_ANONYMOUS_GET    = true
      STORAGE               = "local",
      STORAGE_LOCAL_ROOTDIR = "/charts"
    }

    secure_environment_variables = {
      AZURE_STORAGE_ACCESS_KEY = "${azurerm_storage_account.vaultdemo.primary_access_key}"
    }

    volume {
      name                 = "charts"
      mount_path           = "/charts"
      read_only            = false
      share_name           = "${azurerm_storage_share.charts.name}"
      storage_account_name = "${azurerm_storage_account.vaultdemo.name}"
      storage_account_key  = "${azurerm_storage_account.vaultdemo.primary_access_key}"
    }
  }
}
