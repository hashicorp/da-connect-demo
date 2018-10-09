#!/bin/bash
export VAULT_ADDR=http://vault.service.consul:8200
export VAULT_TOKEN=$(cat /home/ubuntu/.vault_token)

# Enable database backend for postgres
vault secrets enable database

## Setup the plugin
vault write database/config/my-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="db-role" \
    connection_url="postgresql://{{username}}:{{password}}@${db_server}:5432/${db_database}" \
    username="${db_username}@emojify-db" \
    password="${db_password}"

## Confgiure the role
vault write database/roles/db-role \
    db_name=my-database \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; \
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\"; \
        GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"


# Create a K8s role allowing access from our auth pod
vault write auth/kubernetes/role/emojify-auth \
    bound_service_account_names=emojify-auth \
    bound_service_account_namespaces=default \
    policies=default,emojify-auth \
    ttl=1h

# Configure static secrets
vault kv put secret/emojify-auth \
	redis_key=${redis_key} \
	redis_server=${redis_server} \
	db_server=${db_server} \
	keratin_key_base=my-authn-test-secret \
	keratin_auth_username=hello \
	keratin_auth_password=password \
    github_auth_client_id=${github_auth_client_id} \
    github_auth_client_secret=${github_auth_client_secret}

## Create policy allowing access to the db-role and k8s auth
tee ./policy.hcl > /dev/null <<"EOF"
path "database/creds/db-role" {
  capabilities = ["read"]
}
path "secret/data/emojify-auth" {
  capabilities = ["read"]
}
EOF
vault policy write emojify-auth policy.hcl
