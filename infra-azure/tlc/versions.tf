# Second container app for The Lottery Corporation-branded build.
#
# Separate Terraform root with its OWN state, on purpose: the main stack's
# state lives (or lived) on the machine that first applied it, and this
# root must be runnable from Azure Cloud Shell without it. Everything
# expensive is reused through data sources - the Container Apps
# environment, the backend managed identity, Key Vault secrets, Blob,
# MySQL and Azure OpenAI in rg-aipapp. The only resource created here is
# one scale-to-zero container app, so at rest it costs cents.

terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
