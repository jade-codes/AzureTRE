# Azure DevOps Project Service

The following bundle creates an Azure DevOps Project in the target organization.

## Requirements

Before the service can be run the following pre-requisites are required.

- The Azure DevOps Org must be linked to the same Entra ID tenant that the TRE instance is deployed into.
- The Managed Identity of the VM ScaleSet (usually `id-vmss-<tre_ID>`) must be added as a user to the Azure DevOps Organisation.  (NOTE: This must be done by a member of the Entra ID tenant, guest accounts are unable to see the user list and as a result can't add non-email based user accounts)
- The Managed Identity must be assigned to the `Project Collection Administrators` group in Azure DevOps.
- In order to access the project from a workspace Virtual machine, the Azure DevOps Firewall Workspace Service will also need to be installed.

## What gets deployed

The service will deploy an Azure DevOps project using the Terraform provider for Azure DevOps. The project will be created with the following defaults:

- Process Template `TQL 4/5`
- A new repo called `Plans` with branch policies to ensure the minimum number of reviewers
- A wiki page containing instructions on how to use the project.
- A pre-defined set of Work items, including Tool Operating Requirements (TORs) imported from a csv file.
