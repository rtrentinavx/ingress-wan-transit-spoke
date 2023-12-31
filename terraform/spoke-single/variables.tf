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
variable "transit_gateway" { type = string }
variable "resource_group" { type = string }
variable "location" { type = string }
variable "virtual_network_name" { type = string }
variable "address_space" { type = list(string) }
variable "subnet_names" { type = list(string) }
variable "subnet_prefixes" { type = list(string) }
variable "tags" { type = map(string) }
variable "enable_max_performance" { type = bool }
variable "insane_mode" { type = bool }
variable "gw_name" { type = string }
variable "instance_size" { type = string }
variable "greenfield" { type = bool }
variable "custom_routes" {
  type = map(object({
    route_table = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = string
  }))
}