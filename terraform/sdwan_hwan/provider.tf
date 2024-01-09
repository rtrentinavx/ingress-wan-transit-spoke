terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "3.1.2"
    }
  }
  # backend "azurerm" {
  #   resource_group_name  = "syneos-backend-storage-rg"
  #   storage_account_name = "storagesyneostfstate"
  #   container_name       = "state"
  #   key                  = "terraform.tfstate.sdwan"
  # }
}

provider "aviatrix" {
  controller_ip           = data.azurerm_key_vault_secret.secret-avx-controller-public-ip.value
  username                = data.azurerm_key_vault_secret.secret-avx-username.value
  password                = data.azurerm_key_vault_secret.secret-avx-admin-password.value
  skip_version_validation = true
  verify_ssl_certificate  = false
}
provider "azurerm" {
  alias           = "keyvault"
  subscription_id = var.keyvault_subscription_id
  features {}
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}