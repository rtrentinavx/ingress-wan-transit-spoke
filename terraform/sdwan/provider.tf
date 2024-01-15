terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "3.1.3"
    }
  }
  backend "azurerm" {
    resource_group_name  = "syneos-backend-storage-rg"
    storage_account_name = "storagesyneostfstate"
    container_name       = "state"
    key                  = "terraform.tfstate.sdwan"
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
  alias                   = "keyvault"
  subscription_id         = var.keyvault_subscription_id
  client_id               = var.keyvault_client_id
  client_secret_file_path = var.keyvault_client_secret_file_path
  tenant_id               = var.keyvault_tenant_id
  features {}
}

provider "azurerm" {
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret_file_path = var.client_secret_file_path
  tenant_id               = var.tenant_id
  features {}
}