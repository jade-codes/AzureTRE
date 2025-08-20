output "project_url" {
  value       = "https://dev.azure.com/${var.azure_devops_organisation}/${var.azure_devops_project}"
  description = "The URL of the Azure DevOps project."
}
