data "azurerm_subscription" "current" {
}

data "azurerm_resource_group" "resource-group" {
  name = var.resource_group
}

data "azurerm_resource_group" "rg-keyvault" {
  provider = azurerm.keyvault
  name     = var.rg-keyvault
}

data "azurerm_key_vault" "keyvault" {
  provider            = azurerm.keyvault
  name                = var.keyvault_name
  resource_group_name = data.azurerm_resource_group.rg-keyvault.name
}

data "azurerm_key_vault_secret" "secret-avx-controller-public-ip" {
  provider     = azurerm.keyvault
  name         = "avx-controller-public-ip"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
data "azurerm_key_vault_secret" "secret-avx-username" {
  provider     = azurerm.keyvault
  name         = "avx-username"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
data "azurerm_key_vault_secret" "secret-avx-admin-password" {
  provider     = azurerm.keyvault
  name         = "avx-admin-password"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_virtual_network" "virtual_network" {
  count               = var.greenfield == true ? 0 : 1
  name                = var.virtual_network_name
  resource_group_name = var.resource_group
}