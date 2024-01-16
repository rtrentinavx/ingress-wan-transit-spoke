resource "random_id" "randomId" {
  keepers = {
    resource_group = data.azurerm_resource_group.resource-group.name
  }
  byte_length = 8
}

resource "azurerm_storage_account" "fgtstorageaccount" {
  name                          = "diag${random_id.randomId.hex}"
  resource_group_name           = data.azurerm_resource_group.resource-group.name
  location                      = data.azurerm_resource_group.resource-group.location
  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  public_network_access_enabled = false
  tags                          = var.tags
}