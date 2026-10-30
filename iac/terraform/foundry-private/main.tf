# =============================================================================
# Private Microsoft Foundry resource + project + model deployment (Terraform)
# -----------------------------------------------------------------------------
# Same design as ../../bicep/foundry-private. Uses:
#   - azapi  for Foundry resources (new Foundry features land in AzAPI first)
#   - azurerm for the private endpoint
# Check the latest API versions in the Azure/AI-Landing-Zones Terraform code
# before using this beyond a lab.
# =============================================================================

terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# -----------------------------------------------------------------------------
# 1. Foundry resource
# -----------------------------------------------------------------------------
resource "azapi_resource" "foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = var.foundry_name
  parent_id = data.azurerm_resource_group.rg.id
  location  = var.location
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      customSubDomainName    = var.foundry_name
      allowProjectManagement = true
      disableLocalAuth       = true       # Entra ID only
      publicNetworkAccess    = "Disabled" # private endpoint only
      networkAcls = {
        defaultAction = "Deny"
      }
    }
  }

  response_export_values = ["properties.endpoint"]
}

# -----------------------------------------------------------------------------
# 2. Foundry project
# -----------------------------------------------------------------------------
resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = var.project_name
  parent_id = azapi_resource.foundry.id
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = var.project_name
      description = "Platform demo project"
    }
  }
}

# -----------------------------------------------------------------------------
# 3. Model deployment
# -----------------------------------------------------------------------------
resource "azapi_resource" "model" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"
  name      = var.model_name
  parent_id = azapi_resource.foundry.id

  body = {
    sku = {
      name     = var.deployment_sku
      capacity = var.capacity_k
    }
    properties = {
      model = {
        format  = "OpenAI"
        name    = var.model_name
        version = var.model_version
      }
    }
  }

  depends_on = [azapi_resource.project]
}

# -----------------------------------------------------------------------------
# 4. Private endpoint + DNS zone group
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "foundry" {
  name                = "pe-${var.foundry_name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "plsc-${var.foundry_name}"
    private_connection_resource_id = azapi_resource.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.create_dns_zone_group && length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
}

output "foundry_id" {
  value = azapi_resource.foundry.id
}

output "foundry_endpoint" {
  value = azapi_resource.foundry.output.properties.endpoint
}

output "private_endpoint_ip" {
  value = azurerm_private_endpoint.foundry.private_service_connection[0].private_ip_address
}
