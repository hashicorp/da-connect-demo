variable "machinebox_key" {
  description = "API Key for machinebox"
}

variable "cloudflare_enabled" {
  description = "Enable cloudflare CDN?"
  default     = false
}

variable "cloudflare_domain" {
  description = "Cloudflare domain name"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id"
}

variable "github_auth_client_id" {
  description = "GitHub client id for GitHub oAuth"
}

variable "github_auth_client_secret" {
  description = "GitHub client secret for GitHub oAuth"
}

variable "images_resource_group" {}

variable "remote_state_resource_group_name" {}

variable "remote_state_storage_account_name" {}

variable "remote_state_container_name" {}
