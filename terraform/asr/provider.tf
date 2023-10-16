terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    resource_group_name  = "syneos-backend-storage-rg"
    storage_account_name = "storagesyneostfstate"
    container_name       = "state"
    key                  = "terraform.tfstate.asr"
  }
}

provider "azurerm" {
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_secret_file_path = var.client_secret_file_path
  tenant_id               = var.tenant_id
  features {}
}