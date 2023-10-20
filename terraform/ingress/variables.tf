variable "keyvault_subscription_id" { type = string }
variable "keyvault_client_id" { type = string }
variable "keyvault_client_secret_file_path" { type = string }
variable "keyvault_tenant_id" { type = string }
variable "rg-keyvault" { type = string }
variable "keyvault_name" { type = string }
variable "subscription_id" { type = string }
variable "client_id" { type = string }
variable "client_secret_file_path" { type = string }
variable "tenant_id" { type = string }
variable "resource_group" { type = string }
variable "location" { type = string }
variable "virtual_network_name" { type = string }
variable "address_space" { type = list(string) }
variable "subnet_names" { type = list(string) }
variable "subnet_prefixes" { type = list(string) }
variable "appgw_name" { type = string }
variable "fe-port" { type = string }
variable "fe-protocol" { type = string }
variable "be-path" { type = string }
variable "be-port" { type = string }
variable "be-protocol" { type = string }
variable ssl_certificate { type = sting }
variable "tags" { type = map(string) }
variable "transit_gateway" { type = string }
variable "firewall_name" { type = list(string) }
variable "fw_instance_size" { type = string }
variable "firewall_image_version" { type = string }
variable "zone1" {
  type    = string
  default = "1"
}
variable "zone2" {
  type    = string
  default = "2"
}
variable "firewall_image" { default = "payg" }
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
variable "adminsport" {
  type    = string
  default = "8443"
}
variable "activeport1" { type = string }
variable "activeport1mask" { type = string }
variable "activeport2" { type = string }
variable "activeport2mask" { type = string }
variable "activeport3" { type = string }
variable "activeport3mask" { type = string }
variable "passiveport1" { type = string }
variable "passiveport1mask" { type = string }
variable "passiveport2" { type = string }
variable "passiveport2mask" { type = string }
variable "passiveport3" { type = string }
variable "passiveport3mask" { type = string }
variable "port1gateway" { type = string }
variable "port2gateway" { type = string }
variable "forti_as_num" { type = string }
variable "license" {
  type    = string
  default = "license.txt"
}
variable "license2" {
  type    = string
  default = "license2.txt"
}

