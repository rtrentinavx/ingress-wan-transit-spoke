variable "avx_controller_admin" {
  type    = string
  default = "admin"
}
variable "avx_controller_public_ip" { type = string }
variable "avx_controller_admin_password" { type = string }
variable "transit_gateway_name" { type = string }
variable "vpc_name" { type = string }
variable "gw_name" { type = string }
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