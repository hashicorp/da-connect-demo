# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Run consul on kubernetes
resource "helm_release" "consul" {
  name    = "consul"
  chart   = "${path.module}/helm_charts/consul_helm"
  timeout = 1000

  set {
    name  = "version"
    value = "0.3.0"
  }

  set {
    name  = "dns.enabled"
    value = true
  }

  set {
    name  = "ui.enabled"
    value = true
  }

  set {
    name  = "syncCatalog.enabled"
    value = true
  }

  set {
    name  = "connectInject.enabled"
    value = true
  }

  set {
    name  = "client.grpc"
    value = true
  }

  set {
    name  = "client.enabled"
    value = true
  }

  set {
    name  = "dns.enabled"
    value = true
  }
}
