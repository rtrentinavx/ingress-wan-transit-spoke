module "vnet" {
  count               = var.greenfield == true ? 1 : 0
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

resource "azurerm_route_table" "private_route_table" {
  name                          = "rt-private"
  location                      = data.azurerm_resource_group.resource-group.location
  resource_group_name           = var.resource_group
  disable_bgp_route_propagation = true

  route {
      name           = "avx-rt-default"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "None"
  }
}

resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  for_each = var.subnet_names == "gw-subnet" ? [0] : [1]
  route_table_id = azurerm_route_table.private_route_table.id
  subnet_id      = module.vnet.vnet_subnets_name_id[each.key]
}

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "7.0.0"
  azure_region = data.azurerm_resource_group.resource-group.location
}

module "mc-spoke" {
  source                 = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                = "1.6.6"
  cloud                  = "Azure"
  name                   = var.virtual_network_name
  region                 = module.regions.location
  cidr                   = element(var.address_space, 0)
  account                = data.azurerm_subscription.current.display_name
  attached = var.greenfield == true ? true : false 
  transit_gw             = var.transit_gateway
  enable_max_performance = var.enable_max_performance != false ? var.enable_max_performance : null
  insane_mode            = var.insane_mode
  gw_name                = var.gw_name
  gw_subnet              = var.subnet_prefixes[0]
  hagw_subnet            = var.subnet_prefixes[1]
  inspection             = true
  instance_size          = var.instance_size
  tags                   = var.tags
  use_existing_vpc       = true
  vpc_id                 = var.greenfield == true ? "${module.vnet[0].vnet_name}:${data.azurerm_resource_group.resource-group.name}:${module.vnet[0].vnet_guid}" : "${data.azurerm_virtual_network.virtual_network[0].name}:${data.azurerm_resource_group.resource-group.name}:${data.azurerm_virtual_network.virtual_network[0].guid}"
}
