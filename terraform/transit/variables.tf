variable "subscription_id" { type = string }
variable "client_id" { type = string }
variable "client_secret_file_path" { type = string }
variable "tenant_id" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "storage_account_name" { type = string }
variable "container_name" { type = string }
variable "key" { type = string }
variable "resource_group" { type = string }
variable "virtual_network_name" { type = string }
variable "address_space" { type = string }
variable "rg-keyvault" { type = string }
variable "keyvault_name" { type = string }
variable "gw_name" { type = string }
variable "instance_size" { type = string }
variable "local_as_number" { type = string }
variable "tags" { type = map(string) }
variable "fw_amount" { type = string }
variable "firewall_image" { type = string }
variable "firewall_image_version" { type = string }
variable "fw_instance_size" { type = string }
variable "firewall_name" { type = list(string) }
