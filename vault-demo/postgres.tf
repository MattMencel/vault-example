resource "vault_mount" "db" {
  path = "postgres"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgresql" {
  backend       = "${vault_mount.db.path}"
  name          = "postgresql"
  allowed_roles = ["readonly"]

  postgresql {
    connection_url = "postgresql://${urlencode(var.postgres_user)}:${urlencode(var.postgres_password)}@${var.postgres_url}:5432/${var.postgres_db}"
  }
}

resource "vault_database_secret_backend_role" "readonly" {
  backend = "${vault_mount.db.path}"
  name    = "readonly"
  db_name = "${vault_database_secret_backend_connection.postgresql.name}"
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  default_ttl = "3600"
  max_ttl     = "86400"
}

resource "vault_policy" "app-readonly" {
  name = "apps"

  policy = <<EOT
path "postgres/creds/readonly" {
  capabilities = ["read"]
}
EOT
}

resource "vault_token" "app" {
  policies = ["apps"]

  renewable = true
  ttl       = "24h"
}
output "app_token" {
  value = "${vault_token.app.client_token}"
}
