# Private Foundry: Terraform starter

The Terraform twin of [`../../bicep/foundry-private`](../../bicep/foundry-private). It uses **AzAPI** for Foundry resources, because new Foundry features show up there before they reach AzureRM, and **AzureRM** for the private endpoint.

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

Validated with `terraform validate` (Terraform 1.9, azurerm ~> 4.0, azapi ~> 2.0). Test steps and common failures are in the [Bicep README](../../bicep/foundry-private/README.md#test-it-from-inside-the-network).

For production, use the official Terraform implementation in [Azure/AI-Landing-Zones](https://github.com/Azure/AI-Landing-Zones) and the [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) it builds on.
