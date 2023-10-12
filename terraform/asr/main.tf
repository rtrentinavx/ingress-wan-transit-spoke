
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

resource "azurerm_virtual_network" "ars_vng" {
  name                = "vng-${var.virtual_network_name}"
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  address_space       = azurerm_subnet.terraform-azure-subnet.address_prefixes[subnet01]
  tags = var.tags
}

resource "azurerm_public_ip" "ars_pip" {
  name                = "pip-asr-${var.virtual_network_name}"
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = var.tags
}

resource "azurerm_route_server" "ars" {
  name                             = "ars-${var.virtual_network_name}"
  location            = azurerm_resource_group.terraform-azure-resource-group.location
  resource_group_name = azurerm_resource_group.terraform-azure-resource-group.name
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_pip.id
  subnet_id                        = azurerm_subnet.terraform-azure-subnet.subnet_id[subnet02]
  branch_to_branch_traffic_enabled = true
  tags = var.tags
}