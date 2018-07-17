variable resource_group_name {
  default = "nic-connect-demo"
}

variable location {
  default = "Central US"
}

variable "ssh_public_key" {
  default = "~/.ssh/server_rsa.pub"
}

variable "ssh_private_key" {
  default = "~/.ssh/server_rsa"
}

variable "dns_prefix" {
  default = "connect-demo"
}

variable cluster_name {
  default = "connect-demo"
}

variable "agent_count" {
  default = 3
}

variable "client_id" {}

variable "client_secret" {}
