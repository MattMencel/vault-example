# Vault Demo - Deployment

This demo uses a mix of Terraform and Vault commands to deploy a 3-node Vault cluster, using the new Raft backend, on Azure Kubernetes Service.

## Prerequisites

1. Azure Subscription
2. An SPN with Contributor on the subscription

## Terraform Deployment

Terraform will deploy the following resources:

* A resource group called **vaultdemo** where all remaining resources are created.
* A random label for uniqueness in Azure resource names.
* An Azure KeyVault and KeyVault Key called **autounseal**.
* A Log Analytics Workspace for AKS Metrics.
* An AKS cluster. The generated cluster secrets are used in the Kubernetes and Helm providers.
* A Postgres server and a database named **exampledb**. The password will be in outputs.
* An Azure Container Group instance with the ChartMuseum image.
* A storage account and storage shared named **charts**. This is the storage backend for the ChartMuseum Azure Container Group instance.
* A Kubernetes namespace called **tiller**.
* A `null_resource` with a `local_exec` that downloads the Vault Helm chart repo, and uploads the chart to the ChartMuseum instance.
* A `helm_release` which deploys Vault to the AKS cluster with the additional configuration settings.
* A TLS self-signed cert to be used by the Ingress controller.
* A Public IP with a DNS name
* A Kubernetes TLS Secret and an Nginx Ingress Controller for Vault.

To run the terraform:

1. Install Terraform 0.12
2. Create a `terraform.tfvars` file from the example file and update the fields as required.
3. Run Terraform.
``` sh
terraform init
terraform plan
terraform apply
```

Occasionally, the Vault Helm release doesn't wait long enough for tiller to deploy successfully and Terraform will throw an error. If this happens run `terraform apply` again to complete the install of the Vault Helm resource.

Once Terraform completes, the Vault pods should be in a Running state within a few minutes.

The Public IP and DNS name can take upwards of 15 minutes to become active. Once the nginx-ingress-controller has an EXTERNAL-IP that is no longer pending, the UI should be ready if Vault is unsealed.

```
+ kubectl get service --watch nginx-ingress-controller
NAME                       TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
nginx-ingress-controller   LoadBalancer   10.0.78.54   <pending>     80:32710/TCP,443:31548/TCP   4m56s
```

In the meantime you can Initialize and Unseal Vault in the next section.

## Initialize and Unseal Vault

Vault is configured to AutoUnseal using Azure KeyVault. It should only need to be initialized. The Vault instances will autounseal immediately after they are initialized.

Once Terraform completes, Vault should be deployed in a [3-pod cluster using Raft](https://github.com/hashicorp/vault-helm/issues/40) as it's backend. After the Vault pods are running they must be initialized and unsealed before being used. Check pod status with `kubectl get pods --all-namespaces --watch` and wait for the `vault-0` pod to say "Running". 

You can also check the status of vault with `kubectl exec -ti vault-0 -- vault status`. It's ready for initialization when you see the configuration key/value pairs

### The steps to initialize vault are as follows

1. Initialize *vault-0* which will be the initial leader.

``` sh
kubectl exec -ti vault-0 -- vault operator init
```

2. Store the Initial Root Token for later use.
3. For each other `vault` pod (1 and 2) join the raft cluster. They will initialize and autounseal once joined.

``` sh
kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-headless:8200
kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-headless:8200
```

4. After logging into Vault using a token (e.g. Initial Root Token), you can check the configuration of Raft.

``` sh
kubectl exec -ti vault-0 -- vault login
kubectl exec -ti vault-0 -- vault operator raft configuration -format=json
```

## Vault UI

Once Vault is initialized and unsealed, the UI will be available at the URL in the outputs.

## Vault CLI

Export the following variables in your console where you will run the `vault-demo` Terraform steps.

```
export VAULT_TOKEN=${INITIAL_ROOT_TOKEN}
export VAULT_URI=${VAULT_UI_FQDN}
export VAULT_SKIP_VERIFY=true
```

`VAULT_SKIP_VERIFY=true` should **ONLY** be used in a demo environment!

## Redeploying Vault Chart

If you run into problems, or just want to deploy a new copy of the vault cluster to try something different, run the following commands.

Delete the Vault PVCs first:

``` sh
# The console won't return control to until the vault pods the PVCs are attached to are removed, which happens in the terraform taint/apply step.
# So once you see the message that it is deleting each PVC, hit CTRL-C.
kubectl delete pvc data-vault-0
kubectl delete pvc data-vault-1
kubectl delete pvc data-vault-2
```

Taint the helm release and run terraform apply:

``` sh
terraform taint helm_release.vault
terraform apply
```

Once re-deployed you will need to walk through the initialization and unseal steps again.

If the above steps don't work, `terraform destroy` then `terraform apply`.

## TODO

1. Setup Vault using AutoUnseal with the Key Vault Key.
2. Demo Audit Log
