# Azure DevOps Workspace Service

See: [Azure DevOps Service](https://learn.microsoft.com/en-us/azure/devops/user-guide/what-is-azure-devops)

## Prerequisites

- [A base workspace deployed](../workspaces/base.md)

- The Azure DevOps workspace service container image needs building and pushing:

  `make workspace_service_bundle BUNDLE=azuredevops`

## Authenticating

1. Once logged into a virtual machine in the workspace, open the browser and navigate to the target azure devops org.  You will be prompted to log in using your credentials.

