terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"      
      version = "~> 4.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription
}
