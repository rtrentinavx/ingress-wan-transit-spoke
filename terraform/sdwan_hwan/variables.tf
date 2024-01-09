variable "keyvault_subscription_id" { type = string }
variable "rg-keyvault" { type = string }
variable "keyvault_name" { type = string }
variable "subscription_id" { type = string }
variable "location" { type = string }
variable "management" { type = string }
variable "tags" { type = map(string) }
variable "transit_gateway" { type = string }
variable "azure_region_summary" { type = string }
variable "ars_resource_group" { type = string }
variable "ars_virtual_network_name" { type = string }
variable "ars_address_space" { type = list(string) }
variable "ars_subnet_names" { type = list(string) }
variable "ars_subnet_prefixes" { type = list(string) }
variable "express_route_location" { type = bool }
variable "vng_name" {
  type    = string
  default = null
}
variable "vpn_gateway_type" {
  type    = string
  default = null
}
variable "vpn_type" {
  type    = string
  default = null
}
variable "vpn_sku" {
  type    = string
  default = null
}
variable "sdwan_resource_group" { type = string }
variable "sdwan_virtual_network_name" { type = string }
variable "sdwan_address_space" { type = list(string) }
variable "sdwan_subnet_names" { type = list(string) }
variable "sdwan_subnet_prefixes" { type = list(string) }
variable "transit_to_ars" { type = string }
variable "transit_to_sdwan" { type = string }

variable "lb_port" { type = map(any) }
variable "lb_probe" { type = map(any) }
variable "elb_name" { type = string }
variable "elb_frontend_ip_name" { type = string }

variable "firewall_name" { type = list(string) }
variable "firewall_instance_size" { type = string }
variable "firewall_image_version" { type = string }
variable "zone1" {
  type    = string
  default = "1"
}
variable "zone2" {
  type    = string
  default = "2"
}
variable "firewall_image" { default = "byol" }
variable "accelerate" { default = "true" }
variable "publisher" {
  type    = string
  default = "fortinet"
}
variable "fgtoffer" {
  type    = string
  default = "fortinet_fortigate-vm_v5"
}
variable "fgtsku" {
  type = map(any)
  default = {
    byol = "fortinet_fg-vm"
    payg = "fortinet_fg-vm_payg_2023"
  }
}

variable "firewall_as_num" { type = string }
variable "fw_loopback" { type = string }
variable "license" {
  type    = string
  default = "license.txt"
}
variable "license2" {
  type    = string
  default = "license2.txt"
}

