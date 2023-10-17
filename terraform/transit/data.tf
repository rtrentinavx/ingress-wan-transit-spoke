data "azurerm_subscription" "current" {
}
data "azurerm_resource_group" "rg-keyvault" {
  name = var.rg-keyvault
}
data "azurerm_key_vault" "keyvault" {
  name                = var.keyvault_name
  resource_group_name = data.azurerm_resource_group.rg-keyvault.name
}
data "azurerm_key_vault_secret" "secret-avx-controller-public-ip" {
  name         = "avx-controller-public-ip"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
data "azurerm_key_vault_secret" "secret-avx-username" {
  name         = "avx-username"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
data "azurerm_key_vault_secret" "secret-avx-admin-password" {
  name         = "avx-admin-password"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
data "azurerm_key_vault_secret" "secret-firewall-username" {
  name         = "firewall-username"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
data "azurerm_key_vault_secret" "secret-firewall-password" {
  name         = "firewall-password"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
data "azurerm_resource_group" "resource-group" {
  name = var.resource_group
}

