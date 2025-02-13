# terraform-ghost-log-forwarder-azure
Terraform module which deploys a [Ghost](https://ghostsecurity.com/) log forwarder to Azure for sending [Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/) access logs to the Ghost platform.

Refer to the [Log Based Discovery](https://docs.ghostsecurity.com/en/articles/9471377-log-based-discovery-alpha) documentation for more on how this is used in the Ghost platform.

## Considerations
- The module expects a Ghost API key with `write:logs` permissions.
    - Use the [API Keys](https://app.ghostsecurity.com/settings/apikeys) page to generate a new key and store this in Azure key vault.

<!-- BEGIN_TF_DOCS -->
## Providers

No providers.

## Outputs

No outputs.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_url"></a> [api\_url](#input\_api\_url) | Base URL for the Ghost API | `string` | `"https://api.ghostsecurity.com"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name for this log forwarder. This must be unique within your Azure account. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to all resources. By default resources are tagged with ghost:forwarder\_name. | `map(string)` | `{}` | no |

## Resources

No resources.
<!-- END_TF_DOCS -->
