// Create basic work items for initial work

// Create a work item for creating a plan
resource "azuredevops_workitem" "create_plan_work_item" {
  project_id = resource.azuredevops_project.project.id
  title      = "Create a project plan"
  type       = "User Story"
  state      = "New"
}

// Create a work item for creating new requirements
resource "azuredevops_workitem" "create_new_requirements_work_item" {
  project_id = resource.azuredevops_project.project.id
  title      = "Create tool requirements"
  type       = "User Story"
  state      = "New"
}

// Create a work item for requirements review
resource "azuredevops_workitem" "create_new_design_work_item" {
  project_id = resource.azuredevops_project.project.id
  title      = "Create tool design"
  type       = "User Story"
  state      = "New"
}

// Create a work item for requirements review
resource "azuredevops_workitem" "requirements_review_work_item" {
  project_id = resource.azuredevops_project.project.id
  title      = "Requirements review"
  type       = "Requirements Review"
  state      = "New"
}

// Create a work item for design review
resource "azuredevops_workitem" "design_work_item" {
  project_id = resource.azuredevops_project.project.id
  title      = "Tool design"
  type       = "Design"
  state      = "New"
}
