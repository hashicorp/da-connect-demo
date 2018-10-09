#!/bin/bash
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=${vault_token}

# Enable the Azure auth backend
vault auth enable azure

## Confgiure Vaults access to AD
vault write auth/azure/config \
    tenant_id=${tennant_id} \
    resource=https://management.azure.com/ \
    client_id=${client_id} \
    client_secret=${client_secret}

## Create a role allowing the jumpbox VM to auth Vault
vault write auth/azure/role/jumpbox-role \
    policies="admin" \
    bound_service_principal_ids=${jumpbox_service_prinicpal_id}

## Create a policy for the jumpbox granting Admin access
tee ./policy.hcl > /dev/null <<"EOF"
path "*" {
  capabilities = ["create", "read", "update", "delete"]
}
EOF
vault policy write admin policy.hcl


# Enable the Kuberentes auth endpoint
vault auth enable kubernetes

## Configure the endpoint
echo "${k8s_cluster_ca_certificate}" >> ./cluster_ca_certificate.pem

vault write auth/kubernetes/config \
  kubernetes_host=${k8s_host} \
  kubernetes_ca_cert=@./cluster_ca_certificate.pem
