variable "subscription_id" { type = string }
variable "client_id" { type = string }
variable "client_secret_file_path" { type = string }
variable "tenant_id" { type = string }
variable "location" { type = string }
variable "resource_group" { type = string }
variable "virtual_network_name" { type = string }
variable "address_space" { type = string }
variable "rg-keyvault" { type = string }
variable "keyvault_name" { type = string }
variable "gw_name" { type = string }
variable "transit_gateway_name" { type = string }
variable "enable_max_performance" { type = bool }
variable "insane_mode" { type = bool }
variable "instance_size" { type = string }
variable "inspection" { type = bool }
variable "tags" { type = map(string) }
variable "firewall_name" { type = string }
variable "firewall_size" { type = string }
variable "license_type" { default = "byol" }

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
    payg = "fortinet_fg-vm_payg_2022"
  }
}

variable "firewall_image_version" { type    = string }

variable "vnetcidr" {
  default = "10.1.0.0/16"
}

variable "publiccidr" {
  default = "10.1.0.0/24"
}

variable "privatecidr" {
  default = "10.1.1.0/24"
}

variable "bootstrap-fgtvm" {
  // Change to your own path
  type    = string
  default = "fgtvm.conf"
}

// license file for the fgt
variable "license" {
  // Change to your own byol license file, license.lic
  type    = string
  default = "license.txt"
}