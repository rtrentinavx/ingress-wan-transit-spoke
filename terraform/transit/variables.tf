variable "avx_controller_admin" {
  type    = string
  default = "admin"
}
variable "avx_controller_public_ip" { type = string }
variable "location" {
  type = string
}
variable "resource_group" {
  type = string
}
variable "virtual_network_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnet" {
  type = map(object({
    name                        = string
    address_prefixes                      = list(string)
  }))
}
variable "allocate_new_eip" { type = bool }
variable "gw_name" { type = string }
variable "gw_subnet" { type = string }
variable "ha_gw_subnet" { type = string }
variable "instance_size" { type = string }
variable "local_as_number" { type = string }
variable "tags" { type = map(string) }
variable "firewall_image" { type = string }
variable "fw_instance_size" { type = string }
variable "firewall_name" { type = string }
variable "firewall_username" { type = string }
variable "fw_tags" { type = map(string) }
variable "rg-keyvault" {
  type = string
}
variable "keyvault_name" {
  type = string
}