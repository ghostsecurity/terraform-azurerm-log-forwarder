variable "resource_group_name" {
  description = "The name of the resource group to deploy the forwarder resources into."
  type        = string
}

variable "name" {
  description = "Unique name of the forwarder. Multiple forwarders deployed in the same subscription must have unique names."
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to all resources. By default resources are tagged with ghost:forwarder_name."
  type        = map(string)
  default     = {}
}

variable "api_url" {
  description = "Base URL for the Ghost API"
  type        = string
  default     = "https://api.ghostsecurity.com"
}

variable "key_vault_id" {
  description = "ID of Azure key vault which stores the secret key given in api_key_secret_id"
  type        = string
}

variable "api_key_secret_id" {
  description = "Versionless secret Id of a key vault secret that stores a Ghost API key with write:logs permissions."
  type        = string
}

variable "eventhub_name" {
  description = "Name of the EventHub to subscribe to for Application Gateway access log events"
  type        = string
}

variable "eventhub_namespace" {
  description = "Namespace of the EventHub subscribe to for Application Gateway access log events"
  type        = string
}

variable "eventhub_resource_group_name" {
  description = "Resource group name of the EventHub to subscribe to for Application Gateway access log events"
  type        = string
}
