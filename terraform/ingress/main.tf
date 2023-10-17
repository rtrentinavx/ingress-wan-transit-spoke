resource "azurerm_resource_group" "resouce_group" {
  name     = var.resource_group
  location = var.location
}

resource "aviatrix_vpc" "azure_vnet" {
  cloud_type           = 8
  account_name         = data.azurerm_subscription.current.display_name
  region               = azurerm_resource_group.resouce_group.location
  name                 = var.virtual_network_name
  cidr                 = var.address_space
  aviatrix_firenet_vpc = false
  num_of_subnet_pairs = 3 
  resource_group = azurerm_resource_group.resouce_group.name
}

module "regions" {
  source       = "claranet/regions/azurerm"
  version      = "7.0.0"
  azure_region = azurerm_resource_group.resource-group.location
}

module "mc-spoke" {
  source                 = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version                = "1.6.5"
  cloud                  = "Azure"
  name                   = var.virtual_network_name
  gw_name                = var.gw_name
  region                 = module.regions.location
  cidr                   = var.address_space
  account                = data.azurerm_subscription.current.display_name
  resource_group         = azurerm_resource_group.resource-group.name
  transit_gw             = var.transit_gateway_name
  insane_mode            = var.insane_mode
  inspection             = true
  instance_size          = var.instance_size
  enable_max_performance = var.enable_max_performance

}

resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.resouce_group.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "fgtstorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.resouce_group.name
  location                 = azurerm_resource_group.resouce_group.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  tags                     = var.tags
}

