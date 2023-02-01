# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "test_vnet_id" {
  value = "${module.network.vnet_id}"
}
