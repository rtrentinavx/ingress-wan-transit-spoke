locals {
  rfc1918           = { "192.168.0.0-16" = "192.168.0.0/16", "172.16.0.0-12" = "172.16.0.0/12", "10.0.0.0-8" = "10.0.0.0/8", }
  subnet_map        = { for idx, name in var.subnet_names : idx => name }
  route_table_names = [for rt in azurerm_route_table.route_table : "${rt.name}:${data.azurerm_resource_group.resource-group.name}" if rt.name != azurerm_route_table.route_table["2"].name ]
}

resource "azurerm_route_table" "route_table" {
  for_each            = local.subnet_map
  location            = data.azurerm_resource_group.resource-group.location
  name                = "rtb-${each.value}"
  resource_group_name = data.azurerm_resource_group.resource-group.name
  tags                = var.tags
}

resource "azurerm_route" "route-rfc1918" {
  for_each               = local.rfc1918
  name                   = "rt-${each.key}"
  resource_group_name    = data.azurerm_resource_group.resource-group.name
  route_table_name       = azurerm_route_table.route_table["2"].name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.loadbalancer-internal.azurerm_lb_frontend_ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "route_table-association" {
  for_each       = local.subnet_map
  subnet_id      = data.azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.route_table[each.key].id
}