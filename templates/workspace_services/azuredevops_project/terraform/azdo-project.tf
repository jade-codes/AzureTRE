// Create a project.

resource "azuredevops_project" "project" {
  name        = var.azure_devops_project
  description = "Project ${var.azure_devops_project} created by workspace ${local.short_workspace_id}"

  // This process must be defined in the Azure DevOps organization
  // and should contain the required work item types.
  work_item_template = "TQL 4-5"
}
