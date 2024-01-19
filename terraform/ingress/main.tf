module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "4.1.0"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  use_for_each        = true
  vnet_location       = data.azurerm_resource_group.resource-group.location
  address_space       = var.address_space
  vnet_name           = var.virtual_network_name
  subnet_names        = var.subnet_names
  subnet_prefixes     = var.subnet_prefixes
  tags                = var.tags
}

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "7.0.0"
  azure_region = data.azurerm_resource_group.resource-group.location
}

module "mc-spoke" {
  depends_on             = [azurerm_virtual_machine.firewall-1, azurerm_virtual_machine.firewall-2]
  source                 = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                = "1.6.5"
  cloud                  = "Azure"
  name                   = var.virtual_network_name
  region                 = module.regions.location
  cidr                   = element(var.address_space, 0)
  account                = data.azurerm_subscription.current.display_name
  attached               = false
  transit_gw             = var.transit_gateway
  enable_max_performance = var.enable_max_performance != false ? var.enable_max_performance : null
  insane_mode            = var.insane_mode
  gw_name                = var.gw_name
  gw_subnet              = var.subnet_prefixes[0]
  hagw_subnet            = var.subnet_prefixes[0]
  inspection             = true
  instance_size          = var.instance_size
  tags                   = var.tags
  use_existing_vpc       = true
  vpc_id                 = "${module.vnet.vnet_name}:${data.azurerm_resource_group.resource-group.name}:${module.vnet.vnet_guid}"
}

resource "aviatrix_spoke_transit_attachment" "ingress-spoke" {
  spoke_gw_name   = module.mc-spoke.spoke_gateway.gw_name
  transit_gw_name = data.aviatrix_transit_gateway.transit_gateway.gw_name
  route_tables    = local.route_table_names
}