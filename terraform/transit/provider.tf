terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.76.0"
    }
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "3.1.2"
    }
  }
  backend "azurerm" {
    resource_group_name  = var.resource_group_name
    storage_account_name = var.storage_account_name
    container_name       = var.container_name
    key                  = var.key
  }
}

provider "aviatrix" {
  controller_ip           = data.azurerm_key_vault_secret.secret-avx-controller-public-ip.value
  username                = data.azurerm_key_vault_secret.secret-avx-username.value
  password                = data.azurerm_key_vault_secret.secret-avx-admin-password.value
  skip_version_validation = true
  verify_ssl_certificate  = false
}

provider "azurerm" {
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret_file_path = var.client_secret_file_path
  tenant_id               = var.tenant_id
  features {}
}