module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "7.0.0"
  azure_region = data.azurerm_resource_group.resource-group.location
}
module "mc-transit" {
  source                        = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version                       = "2.5.1"
  account                       = data.azurerm_subscription.current.display_name
  bgp_ecmp                      = true
  bgp_lan_interfaces_count      = 2
  cloud                         = "Azure"
  cidr                          = var.address_space
  connected_transit             = true
  enable_bgp_over_lan           = true
  enable_egress_transit_firenet = true
  enable_transit_firenet        = true
  insane_mode                   = true
  gw_name                       = var.gw_name
  name                          = var.virtual_network_name
  region                        = module.regions.location
  resource_group                = data.azurerm_resource_group.resource-group.name
  tags                          = var.tags
}
module "mc-firenet" {
  source                 = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version                = "1.5.2"
  custom_fw_names        = var.firewall_name
  egress_enabled         = true
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image
  fw_amount              = var.fw_amount
  username               = data.azurerm_key_vault_secret.secret-firewall-username.value
  password               = data.azurerm_key_vault_secret.secret-firewall-password.value
  transit_module         = module.mc-transit
  tags                   = var.tags
}
