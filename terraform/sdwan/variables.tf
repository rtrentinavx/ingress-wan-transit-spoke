variable "resource_group" { type = string }
variable "location" { type = string }
variable "virtual_network_name" { type = string }
variable "address_space" { type = list(string) }
variable "subnet" {
  type = map(object({
    name                        = string
    address_prefixes                      = list(string)
  }))
}