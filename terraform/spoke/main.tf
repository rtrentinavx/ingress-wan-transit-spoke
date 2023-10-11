
resource "azurerm_resource_group" "terraform-azure-resource-group" {
    name = var.resource_group
    location = var.location
    tags = {}
    }

resource "azurerm_virtual_network" "terraform-azure-virtual_network" {
  depends_on = [
    azurerm_resource_group.terraform-azure-resource-group
  ]
  name = var.virtual_network_name
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  address_space = var.address_space
  location = azurerm_resource_group.terraform-azure-resource-group.location
  tags = {}
}

resource "azurem_subnet" "terraform-azure-subnet" {
  depends_on = [
    azurerm_virtual_network.terraform-azure-virtual_network
  ]
  for_each = var.subnet
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  virtual_network_name = azurerm_virtual_network.terraform-azure-virtual_network.name
  name = each.value.name
  address_prefixes = each.value.address_prefixes
}

resource "azurerm_route_table" "route_table" {
  for_each                      = var.subnet
  name                          = "avx-rtb-${azurerm_subnet.terraform-azure-subnet.subnet_name[each.key]}"
  location                      = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name           = azurerm_resource_group.terraform-azure-resource-group.name
  disable_bgp_route_propagation = true

  route {
    name           = "avx-rt-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "None"
  }
}

resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  depends_on = [
    azurerm_route_table.route_table
  ]
  for_each       = var.subnet
  route_table_id = azurerm_route_table.route_table[each.key].id
  subnet_id      = azurem_subnet.terraform-azure-subnet.subnet_id[each.key]
}

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "6.1.0"
  azure_region = azurem_resource_group.terraform-azure-resource-group.location
}

module "mc-spoke" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.6.5"
  depends_on = [
    azurerm_subnet_route_table_association.subnet_route_table_association
  ]
  cloud         = "Azure"
  name = var.vpc_name
  gw_name = var.gw_name
  gw_subnet = azurerm_subnet.terraform-azure-subnet.address_prefixes["subnet01"]
  hagw_subnet = azurerm_subnet.terraform-azure-subnet.address_prefixes["subnet02"]
  region = module.regions.location
  cidr = var.address_space
  account = data.azurerm_subscription.current.display_name
  resource_group = azurerm_resource_group.terraform-azure-resource-group.name
  transit_gw = var.transit_gateway_name
  use_existing_vpc = true
  inspection = true
  vpc_id         = "${azurerm_virtual_network.terraform-azure-virtual_network.name}:${azurerm_resource_group.terraform-azure-resource-group.name}:${azurem_virtual_network.terraform-azure-virtual_network.guid}"
}
