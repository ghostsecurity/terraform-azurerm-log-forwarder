# terraform-ghost-log-forwarder-azure
Terraform module which deploys a [Ghost](https://ghostsecurity.com/) log forwarder to Azure for sending [Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/) access logs to the Ghost platform.

Refer to the [Log Based Discovery](https://docs.ghostsecurity.com/en/articles/9471377-log-based-discovery-alpha) documentation for more on how this is used in the Ghost platform.

## Considerations
- The module expects a Ghost API key with `write:logs` permissions.
    - Use the [API Keys](https://app.ghostsecurity.com/settings/apikeys) page to generate a new key and store this in Azure key vault.

<!-- BEGIN_TF_DOCS -->
## Example
The following example deploys a log forwarder.

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
  # Note: example subscription id, not real
  subscription_id = "288dd777-3ad7-43c6-8eb6-731df328105a"
}

module "log_forwarder" {
  source = "../../"

  name     = "fitz-test"
  location = "westus2"
  tags = {
    env = "dev"
  }

  api_url = "https://api.dev.ghostsecurity.com"
  # TODO: use key vault
  api_key = ""

  eventhub_name                = "david-s55a7qrf-eh"
  eventhub_namespace           = "david-s55a7qrf-ehns"
  eventhub_resource_group_name = "david-s55a7qrf"
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
| <a name="input_api_key"></a> [api\_key](#input\_api\_key) | Ghost API key | `string` | n/a | yes |
| <a name="input_api_url"></a> [api\_url](#input\_api\_url) | Base URL for the Ghost API | `string` | `"https://api.ghostsecurity.com"` | no |
| <a name="input_eventhub_name"></a> [eventhub\_name](#input\_eventhub\_name) | Name of the EventHub to subscribe to for Application Gateway access log events | `string` | n/a | yes |
| <a name="input_eventhub_namespace"></a> [eventhub\_namespace](#input\_eventhub\_namespace) | Namespace of the EventHub subscribe to for Application Gateway access log events | `string` | n/a | yes |
| <a name="input_eventhub_resource_group_name"></a> [eventhub\_resource\_group\_name](#input\_eventhub\_resource\_group\_name) | Resource group name of the EventHub to subscribe to for Application Gateway access log events | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location for the resource group and related function resources | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name for the log forwarder. Must be unique within your subscription. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to all resources. By default resources are tagged with ghost:forwarder\_name. | `map(string)` | `{}` | no |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_insights.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_eventhub_authorization_rule.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventhub_authorization_rule) | resource |
| [azurerm_linux_function_app.function](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_resource_group.forwarder](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_service_plan.function_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |
| [azurerm_storage_account.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [random_string.storage_account](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
<!-- END_TF_DOCS -->
