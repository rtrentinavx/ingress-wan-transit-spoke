data "azurerm_subscription" "current" {
}

data "azurerm_resource_group" "rg-keyvault" {
    name = "${var.rg-keyvault}"
}

data "azurerm_key_vault" "keyvault" {
    name = "${var.keyvault_name}"
    resource_group_name = "${data.azurerm_resource_group.rg_keyvault.name}"
}

data "azurerm_key_vault_secret" "secret-avx-admin-password" {
    name = "avx-admin-password"
     key_vault_id = "${data.azurerm_key_vault.keyvault.id}"
}