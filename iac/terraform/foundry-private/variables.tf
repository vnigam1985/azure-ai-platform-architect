variable "subscription_id" {
  description = "Subscription that will hold the Foundry resource."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group for the Foundry resource."
  type        = string
}

variable "location" {
  description = "Azure region. Pick one where your model and deployment type are available."
  type        = string
  default     = "canadaeast"
}

variable "foundry_name" {
  description = "Globally unique Foundry resource name (also the custom subdomain)."
  type        = string
}

variable "project_name" {
  description = "Foundry project name."
  type        = string
  default     = "proj-platform-demo"
}

variable "model_name" {
  description = "Model to deploy."
  type        = string
  default     = "gpt-4.1"
}

variable "model_version" {
  description = "Model version. Check the Foundry Models catalog."
  type        = string
  default     = "2025-04-14"
}

variable "deployment_sku" {
  description = "GlobalStandard, DataZoneStandard or Standard. GlobalStandard may process data outside your region."
  type        = string
  default     = "GlobalStandard"

  validation {
    condition     = contains(["GlobalStandard", "DataZoneStandard", "Standard"], var.deployment_sku)
    error_message = "deployment_sku must be GlobalStandard, DataZoneStandard or Standard."
  }
}

variable "capacity_k" {
  description = "Capacity in thousands of tokens per minute."
  type        = number
  default     = 10
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint."
  type        = string
}

variable "create_dns_zone_group" {
  description = "Set false if Azure Policy (DeployIfNotExists) registers DNS records in your landing zone."
  type        = bool
  default     = true
}

variable "private_dns_zone_ids" {
  description = "IDs of privatelink.cognitiveservices.azure.com, privatelink.openai.azure.com and privatelink.services.ai.azure.com."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags for all resources."
  type        = map(string)
  default = {
    workload  = "ai-platform-demo"
    managedBy = "terraform"
  }
}
