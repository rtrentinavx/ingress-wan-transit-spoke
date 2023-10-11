data "azurerm_subscription" "current" {
}
data "aviatrix_transit_gateway" "transit_gateway" {
  gw_name = var.transit_gateway_name
}