# module "vnet" {
#   for_each = var.spokes
#   source              = "Azure/vnet/azurerm"
#   version             = "4.1.0"
#   resource_group_name = data.azurerm_resource_group.resource-group[each.key].name
#   use_for_each        = true
#   vnet_location       = data.azurerm_resource_group.resource-group[each.key].location
#   address_space       = each.value["address_space"]
#   vnet_name           = each.value["virtual_network_name"]
#   subnet_names        = each.value["subnet_names"]
#   subnet_prefixes     = each.value["subnet_prefixes"]
#   tags                = var.tags
# }

module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "4.1.0"
  resource_group_name = null
  use_for_each        = null
  vnet_location       = null
  address_space       = null
  vnet_name           = null
  subnet_names        = null
  subnet_prefixes     = null
  tags                = null
}

module "regions" {
  for_each     = var.spokes
  source       = "claranet/regions/azurerm"
  version      = "7.0.0"
  azure_region = data.azurerm_resource_group.resource-group[each.key].location
}

module "mc-spoke" {
  for_each               = var.spokes
  source                 = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                = "1.6.6"
  cloud                  = "Azure"
  name                   = each.value["virtual_network_name"]
  region                 = module.regions[each.key].location
  cidr                   = element(each.value["address_space"], 0)
  account                = data.azurerm_subscription.current.display_name
  transit_gw             = var.transit_gateway
  enable_max_performance = each.value["enable_max_performance"] != false ? each.value["enable_max_performance"] : null
  insane_mode            = each.value["insane_mode"]
  gw_name                = each.value["gw_name"]
  gw_subnet              = each.value["subnet_prefixes"][0]
  hagw_subnet            = each.value["subnet_prefixes"][1]
  inspection             = true
  instance_size          = each.value["instance_size"]
  tags                   = var.tags
  use_existing_vpc       = true
  vpc_id                 = "${module.vnet[each.key].vnet_name}:${data.azurerm_resource_group.resource-group[each.key].name}:${module.vnet[each.key].vnet_guid}"
}