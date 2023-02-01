# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

/*
# TFE Remote state
terraform {
  backend "atlas" {
    name = "niccorp/emojify-app"
  }
}

data "terraform_remote_state" "core" {
  backend = "atlas"

  config {
    name = "niccorp/emojify-core"
  }
}
*/

terraform {
  backend "azurerm" {
    key = "emojify.app.terraform.tfstate"
  }
}

data "terraform_remote_state" "core" {
  backend = "azurerm"

  config {
    resource_group_name  = "${var.remote_state_resource_group_name}"
    storage_account_name = "${var.remote_state_storage_account_name}"
    container_name       = "${var.remote_state_container_name}"
    key                  = "emojify.core.terraform.tfstate"
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

# Select the domain based on if we are using Cloudflare CDN or not
locals {
  domain = "${var.cloudflare_enabled ? var.cloudflare_domain : data.terraform_remote_state.core.k8s_ingress_fqdn}"
}

# Start our application
resource "helm_release" "emojify" {
  depends_on = ["null_resource.provision_secrets"]

  name    = "emojify"
  chart   = "${path.module}/helm_charts/emojify_helm"
  timeout = 600
  version = "0.3.0"

  set {
    name  = "version"
    value = "0.1.65"
  }

  set {
    name  = "machinebox_key"
    value = "${var.machinebox_key}"
  }

  set {
    name  = "domain"
    value = "${local.domain}"
  }

  set {
    name  = "auth_uri"
    value = "https://${local.domain}/auth"
  }

  set {
    name  = "api_uri"
    value = "https://${local.domain}/api"
  }

  set {
    name  = "home_uri"
    value = "https://${local.domain}"
  }

  set {
    name  = "ingress_ip"
    value = "${data.terraform_remote_state.core.k8s_ingress_ip}"
  }

  set {
    name  = "ingress_fqdn"
    value = "${local.domain}"
  }
}
