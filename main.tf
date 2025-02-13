locals {
  registry_url = "ghostsecurity.azurecr.io"
  image_name   = "forwarder"
  image_tag    = "e86a13b"
}

data "azurerm_resource_group" "forwarder" {
  name = var.resource_group_name
}

# Storage Account used by function.

# A random string is used to generate unique name for the storage account.
# Storage account name must be between 3-24 characters and be globally unique
# within Azure. 
# https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview#storage-account-name
resource "random_string" "storage_account" {
  length  = 24
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_storage_account" "storage" {
  name                     = random_string.storage_account.id
  resource_group_name      = data.azurerm_resource_group.forwarder.name
  location                 = data.azurerm_resource_group.forwarder.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = var.tags
}

resource "azurerm_eventhub_authorization_rule" "function" {
  name                = "ar-ghost-${var.name}"
  eventhub_name       = var.eventhub_name
  namespace_name      = var.eventhub_namespace
  resource_group_name = var.eventhub_resource_group_name
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_eventhub_consumer_group" "function" {
  name                = "cg-ghost-${var.name}"
  eventhub_name       = var.eventhub_name
  namespace_name      = var.eventhub_namespace
  resource_group_name = var.eventhub_resource_group_name
}

resource "azurerm_service_plan" "function_plan" {
  name                = "fp-ghost-${var.name}"
  resource_group_name = data.azurerm_resource_group.forwarder.name
  location            = data.azurerm_resource_group.forwarder.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_application_insights" "function" {
  name                = "ai-ghost-${var.name}"
  resource_group_name = data.azurerm_resource_group.forwarder.name
  location            = data.azurerm_resource_group.forwarder.location
  application_type    = "other"
}

resource "azurerm_linux_function_app" "function" {
  name                        = "fa-ghost-${var.name}"
  resource_group_name         = data.azurerm_resource_group.forwarder.name
  location                    = data.azurerm_resource_group.forwarder.location
  service_plan_id             = azurerm_service_plan.function_plan.id
  storage_account_name        = azurerm_storage_account.storage.name
  storage_account_access_key  = azurerm_storage_account.storage.primary_access_key
  functions_extension_version = "~4"
  builtin_logging_enabled     = false # Should not set both this and app_settings.APPINSIGHTS_INSTRUMENTATIONKEY

  app_settings = {
    EventHubName                 = var.eventhub_name
    EventHubConnectionAppSetting = azurerm_eventhub_authorization_rule.function.primary_connection_string
    EventHubConsumerGroup        = azurerm_eventhub_consumer_group.function.name

    FUNCTION_APP_EDIT_MODE              = "readonly"
    APPINSIGHTS_INSTRUMENTATIONKEY      = azurerm_application_insights.function.instrumentation_key
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"

    GHOST_API_URL = var.api_url
    GHOST_API_KEY = "@Microsoft.KeyVault(SecretUri=${var.api_key_secret_id})"
  }

  site_config {
    always_on                               = true
    container_registry_use_managed_identity = true
    application_stack {
      docker {
        registry_url = local.registry_url

        image_name = local.image_name
        image_tag  = local.image_tag
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

data "azurerm_client_config" "current" {}

# Grant permissions for the managed identity of the function to read secret from provided keyvault
resource "azurerm_key_vault_access_policy" "keyvault_policy" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_function_app.function.identity[0].principal_id
  secret_permissions = [
    "Get"
  ]
}
