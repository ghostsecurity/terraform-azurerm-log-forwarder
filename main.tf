locals {
  default_tags = {
    "ghost:forwarder_name" = var.name
  }

  tags = merge(local.default_tags, var.tags)
}
