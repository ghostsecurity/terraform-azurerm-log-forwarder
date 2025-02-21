terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.18.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Set this to the subscription ID you intend to deploy the forwarder into.
  subscription_id = "de69bdf2-e6ca-40f4-a905-26a8dfc95dc0"
}

# Create a new resource group to deploy the log forwarder into.
resource "azurerm_resource_group" "forwarder" {
  name     = "ghost-forwarder-example"
  location = "eastus"
}

data "azurerm_client_config" "current" {}

# Create a new Key Vault that will be used to securely store the Ghost API
# key used by the forwarder to submit access logs to the platform.
resource "azurerm_key_vault" "vault" {
  name                = "ghost-forwarder-vault"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  location            = azurerm_resource_group.forwarder.location
  resource_group_name = azurerm_resource_group.forwarder.name
  sku_name            = "standard"
}

# Grant user running terraform to manage secrets in the Key Vault
resource "azurerm_key_vault_access_policy" "user" {
  key_vault_id = azurerm_key_vault.vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

# Create a secret in the key vault to store the Ghost API key.
# The API key must have the "write:logs" permission and a new key
# can be created by navigating to https://app.ghostsecurity.com/settings/apikeys.
resource "azurerm_key_vault_secret" "api_key" {
  name         = "GhostAPIKey"
  value        = ""
  key_vault_id = azurerm_key_vault.vault.id
  # Ignore changes to the value which will be set outside of terraform.
  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [
    azurerm_key_vault_access_policy.user
  ]
}

# Deploy the log forwarder into the resource group to send access logs to Ghost.
module "log_forwarder" {
  source = "ghostsecurity/log-forwarder/azure"

  # Resource group to deploy forwarder into.
  resource_group_name = azurerm_resource_group.forwarder.name

  # Name is used to generate unique names for deployed resources.
  # If you deploy multiple forwarders in the same subscription they must have unique names
  name = "dev-forwarder"

  # Additional tags to add to resources created by the module which support tagging.
  tags = {
    env = "dev"
  }

  # Key vault secret created earlier that stores the Ghost API key
  api_key_secret_id = azurerm_key_vault_secret.api_key.versionless_id
  key_vault_id      = azurerm_key_vault.vault.id

  # Specify the EventHub that is receiving Front Door access logs
  # which the forwarder will process and send to Ghost.
  # See https://learn.microsoft.com/en-us/azure/frontdoor/standard-premium/how-to-logs
  # for configuring access logging to send to EventHub.
  eventhub_name                = "eventhub-name"
  eventhub_namespace           = "eventhub-namespace"
  eventhub_resource_group_name = "eventhub-resource-group"

  # Force terraform to wait for the resource group to be created first in the plan.
  depends_on = [
    azurerm_resource_group.forwarder
  ]
}
