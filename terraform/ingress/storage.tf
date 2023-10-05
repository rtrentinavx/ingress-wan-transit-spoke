resource "random_id" "randomId" {
  keepers = {
    resource_group = azurerm_resource_group.resouce_group_ingress_vnet.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "fgtstorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.resouce_group_ingress_vnet.name
  location                 = azurerm_resource_group.resouce_group_ingress_vnet.location
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags = {
    environment = "Terraform Demo"
  }
}
