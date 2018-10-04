data "terraform_remote_state" "core" {
  backend = "local"

  config {
    path = "${path.module}/../core/terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    host = "${data.terraform_remote_state.core.k8s_host}"

    client_certificate     = "${base64decode(data.terraform_remote_state.core.k8s_client_certificate)}"
    client_key             = "${base64decode(data.terraform_remote_state.core.k8s_client_key)}"
    cluster_ca_certificate = "${base64decode(data.terraform_remote_state.core.k8s_cluster_ca_certificate)}"
  }
}

# Start our application
resource "helm_release" "emojify" {
  name    = "emojify"
  chart   = "${path.module}/helm_charts/emojify_helm"
  timeout = 600

  set {
    name  = "machinebox_key"
    value = "${var.machinebox_key}"
  }

  set {
    name  = "database_connection"
    value = "postgres://${azurerm_postgresql_server.emojify_db.administrator_login}@${azurerm_postgresql_server.emojify_db.name}:${azurerm_postgresql_server.emojify_db.administrator_login_password}@${azurerm_postgresql_server.emojify_db.fqdn}:5432/${azurerm_postgresql_database.emojify_db.name}?sslmode=disable"
  }

  set {
    name  = "redis_connection"
    value = "redis://user:${azurerm_redis_cache.emojify_cache.primary_access_key}@${azurerm_redis_cache.emojify_cache.hostname}:${azurerm_redis_cache.emojify_cache.port}/0"
  }
}
