
variable "subscription_id" { type = string }
variable "client_id" { type = string }
variable "client_secret_file_path" { type = string }
variable "tenant_id" { type = string }
variable "vpc_name" { type = string }
variable "resource_group" { type = string }
variable "location" { type = string }
variable "virtual_network_name" { type = string }
variable "address_space" { type = list(string) }
variable "subnet" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
  }))
}
variable "tags" { type = map(string) }
variable "vng_name" { type = string }
variable "vng_primary_tunnel_ip" { type = string }
variable "vng_ha_tunnel_ip" { type = string }