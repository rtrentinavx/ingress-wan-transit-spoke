
resource "azurerm_resource_group" "terraform-azure-resource-group" {
    name = var.resource_group
    location = var.location
    tags = var.tags
    }

resource "azurerm_virtual_network" "terraform-azure-virtual_network" {
  depends_on = [
    azurerm_resource_group.terraform-azure-resource-group
  ]
  name = var.virtual_network_name
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  address_space = var.address_space
  location = azurerm_resource_group.terraform-azure-resource-group.location
    tags = var.tags
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
      tags = var.tags
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
      tags = var.tags
}

resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  depends_on = [
    azurerm_route_table.route_table
  ]
  for_each       = var.subnet
  route_table_id = azurerm_route_table.route_table[each.key].id
  subnet_id      = azurem_subnet.terraform-azure-subnet.subnet_id[each.key]
}

