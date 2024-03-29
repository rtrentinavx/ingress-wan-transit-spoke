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

data "azurerm_key_vault_secret" "secret-firewall-username" {
  name         = "firewall-username"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "secret-firewall-password" {
  name         = "firewall-password"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "secret-forti_client_secret" {
  name         = "forti-client-secret"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_certificate" "cert" {
  name         = var.cert 
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

data "aviatrix_transit_gateway" "transit_gateway" {
  gw_name = var.transit_gateway
}

data "azurerm_subnet" "subnets" {
  depends_on           = [module.vnet]
  for_each             = local.subnet_map
  name                 = each.value
  virtual_network_name = module.vnet.vnet_name
  resource_group_name  = data.azurerm_resource_group.resource-group.name
}
