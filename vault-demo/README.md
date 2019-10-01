# Vault Demo

This demo uses a mix of Terraform and Vault commands to show vault features

## Prerequisites

1. Azure Subscription
2. An SPN with Contributor on the subscription

## Terraform Deployment

Terraform will deploy the following resources:

* Vault Database Secrets Engine for Postgres
* Vault Postgres Backend Connection
* A readonly Backend **Role** for the Postgres Connection
* A Vault **Policy** that maps to the path for the created **Role**
* A new **Token** assigned the created **Policy**

To run the terraform:

1. Install Terraform 0.12
2. Create a `terraform.tfvars` file from the example file and update the fields as required.
3. Run Terraform.

``` sh
terraform init
terraform plan
terraform apply
```

## Test the Vault Token

The new Token is created as a Terraform output. You can use the token to request credentials for the database.

``` sh
VAULT_TOKEN=${NEW_TOKEN_FROM_TERRAFORM} vault read postgres/creds/readonly
```

If you rerun the command you'll notice that Vault returns a different set of credentials each time.

### Validate in Postgres

Connect to Postgres from another window. To get the connection string run `terraform state show vault_database_secret_backend_connection.postgresql` and look for the connection_url.

``` sh
pgcli "${CONNECTION_STRING}"
```

Once logged into Postgres you can use the `\du` command to view users. You should see the v-token-readonly user account and if it's still valid it should have a TIMESTAMP in the `rolvaliduntil` column.

### Renew and Revoke Leases

Back in the original command window, get the lease id with `terraform state show vault_token.app`.

You can renew and revoke the lease with these commands... and run `\du` in the postgres window to view the results after each command.

``` sh 
vault lease renew postgres/creds/readonly/${LEASE_ID}
vault lease revoke postgres/creds/readonly/${LEASE_ID}
```
