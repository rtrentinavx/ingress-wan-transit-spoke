terraform {
  required_version = ">= 1.2.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.40.0"
    }
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "3.75.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = ""
    storage_account_name = ""
    container_name       = ""
    key                  = ""
    use_azuread_auth     = true
  }
}

provider "aviatrix" {
  controller_ip           = var.avx_controller_public_ip
  username                = var.avx_controller_admin
  password                = var.avx_controller_admin_password
  skip_version_validation = true
  verify_ssl_certificate  = false
}

provider "azurerm" {
  features {}
}