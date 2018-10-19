variable resource_group_name {
  default = "emojify-connect-demo"
}

variable location {
  default = "Central US"
}

variable "agent_count" {
  description = "Kubernetes agent count"
  default     = 3
}

variable "cluster_name" {
  description = "Name for the kuberentes cluster"
  default     = "emojify"
}

# Azure API details
variable "client_id" {
  description = "Azure client id for kuberentes and vault auth"
}

variable "client_secret" {
  description = "Azure client secret for kuberentes and vault auth"
}

variable "tennant_id" {
  description = "Azure tennant for vault auth"
}

variable "vault_token" {
  description = "Vault dev token to setup"
  default     = "mytoken"
}

variable "letsencrypt_email" {
  description = "Email address to use for LetsEncrypt certificates"
}

variable "images_resource_group" {}
