variable resource_group_name {
  default = "emojify-connect-demo"
}

variable location {
  default = "Central US"
}

variable "agent_count" {
  default = 3
}

variable "cluster_name" {
  default = "emojify"
}

# Azure API details
variable "client_id" {}

variable "client_secret" {}

variable "tennant_id" {}

variable "vault_token" {
  description = "Vault dev token to setup"
  default     = "mytoken"
}
