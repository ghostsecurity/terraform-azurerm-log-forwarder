variable "name" {
  description = "The name for the log forwarder. Must be unique within your subscription."
  type        = string
  validation {
    condition     = length(var.name) <= 50 && can(regex("^[A-Za-z0-9-]+$", var.name))
    error_message = "Name can only contain alphanumeric characters and hyphens."
  }
}

variable "location" {
  description = "Location for the resource group and related function resources"
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
