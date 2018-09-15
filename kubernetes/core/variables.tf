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

variable "client_id" {}

variable "client_secret" {}

variable "machinebox_key" {
  description = "Machinebox API key, can be obtained from https://machinebox.io/"
}
