variable resource_group_name {
  default = "nic-connect-demo"
}

variable location {
  default = "Central US"
}

variable "client_id" {}

variable "client_secret" {}

variable "machinebox_key" {
  description = "Machinebox API key, can be obtained from https://machinebox.io/"
}
