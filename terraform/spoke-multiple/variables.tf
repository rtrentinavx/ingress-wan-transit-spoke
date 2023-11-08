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
variable "tags" { type = map(string) }
variable "transit_gateway" { type = string }
variable "spokes" {
  type = map(object({
    resource_group         = string
    location               = string
    virtual_network_name   = string
    address_space          = list(string)
    subnet_names           = list(string)
    subnet_prefixes        = list(string)
    enable_max_performance = bool
    insane_mode            = bool
    gw_name                = string
    instance_size          = string
  }))
}

