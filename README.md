# terraform-ghost-log-forwarder-azure
Terraform module which deploys a [Ghost](https://ghostsecurity.com/) log forwarder [Azure Front Door](https://learn.microsoft.com/en-us/azure/frontdoor/standard-premium/how-to-logs) access logs to the Ghost platform.

Refer to the [Log Based Discovery](https://docs.ghostsecurity.com/en/articles/10618998-log-based-api-discovery-azure) documentation for more on how this is used in the Ghost platform.

## Considerations
- The module expects a Ghost API key with `write:logs` permissions.
    - Use the [API Keys](https://app.ghostsecurity.com/settings/apikeys) page to generate a new key and store this in Azure key vault.

<!-- BEGIN_TF_DOCS -->
## Example
The following example deploys a forwarder which listens for Application Gateway access logs from an EventHub.

```hcl
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
```
## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.18.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Outputs

No outputs.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key_secret_id"></a> [api\_key\_secret\_id](#input\_api\_key\_secret\_id) | Versionless secret Id of a key vault secret that stores a Ghost API key with write:logs permissions. | `string` | n/a | yes |
| <a name="input_api_url"></a> [api\_url](#input\_api\_url) | Base URL for the Ghost API | `string` | `"https://api.ghostsecurity.com"` | no |
| <a name="input_eventhub_name"></a> [eventhub\_name](#input\_eventhub\_name) | Name of the EventHub to subscribe to for Application Gateway access log events | `string` | n/a | yes |
| <a name="input_eventhub_namespace"></a> [eventhub\_namespace](#input\_eventhub\_namespace) | Namespace of the EventHub subscribe to for Application Gateway access log events | `string` | n/a | yes |
| <a name="input_eventhub_resource_group_name"></a> [eventhub\_resource\_group\_name](#input\_eventhub\_resource\_group\_name) | Resource group name of the EventHub to subscribe to for Application Gateway access log events | `string` | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | ID of Azure key vault which stores the secret key given in api\_key\_secret\_id | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Unique name of the forwarder. Multiple forwarders deployed in the same subscription must have unique names. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group to deploy the forwarder resources into. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to all resources. By default resources are tagged with ghost:forwarder\_name. | `map(string)` | `{}` | no |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_insights.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_eventhub_authorization_rule.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_authorization_rule) | resource |
| [azurerm_eventhub_consumer_group.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_consumer_group) | resource |
| [azurerm_key_vault_access_policy.keyvault_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_linux_function_app.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_service_plan.function_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [random_string.storage_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.forwarder](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
<!-- END_TF_DOCS -->
