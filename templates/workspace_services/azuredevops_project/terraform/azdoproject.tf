

// Creates an Azure DevOps project
resource "azuredevops_project" "project" {
  name        = var.azure_devops_project
  description = "Project ${var.azure_devops_project} created by workspace ${local.short_workspace_id}"

  // This process must be defined in the Azure DevOps organization
  // and should contain the required work item types.
  work_item_template = "TQL 4-5"
}

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

// Creates a new git repository for storing project plans. Under TQL 4/5,
// plans need change management, so we use a wiki repo pull-request process.
resource "azuredevops_git_repository" "plan_git_repo" {
  project_id     = azuredevops_project.project.id
  name           = "Plans"
  default_branch = "refs/heads/main"
  initialization {
    init_type = "Clean"
  }
  lifecycle {
    ignore_changes = [
      # Ignore changes to initialization to support importing existing repositories
      # Given that a repo now exists, either imported into terraform state or created by terraform
      # We don't care for the configuration of initialization against the existing resource.
      initialization
    ]
  }
}

// Create a branch policy for the plans repo to ensure a pull-request workflow.
resource "azuredevops_branch_policy_min_reviewers" "plan_git_repo_reviewers_policy" {
  project_id = azuredevops_project.project.id
  enabled    = true

  // Set the blocking to true to ensure that the policy must be satisfied before merging
  blocking = true

  // Settings to define the scope of the policy
  settings {

    // For now, just the one reviewer is required.
    reviewer_count = 1

    scope {
      repository_id  = azuredevops_git_repository.plan_git_repo.id
      repository_ref = azuredevops_git_repository.plan_git_repo.default_branch
      match_type     = "Exact"
    }
  }
}

// Create a wiki with repo rules for plans
resource "azuredevops_wiki" "plan_wiki" {
  name          = "Plans"
  project_id    = azuredevops_project.project.id
  repository_id = azuredevops_git_repository.plan_git_repo.id
  version       = "main"
  type          = "codeWiki"
  mapped_path   = "/"
}

// Create a standard wiki for all other content.
resource "azuredevops_wiki" "wiki" {
  name       = "Wiki"
  project_id = azuredevops_project.project.id
  type       = "projectWiki"
}

// Create a wiki page. This will act as a how-to guide for the project.
resource "azuredevops_wiki_page" "home_page" {
  project_id = azuredevops_project.project.id
  wiki_id    = azuredevops_wiki.wiki.id
  path       = "/Home"
  content    = data.template_file.home_page_content.rendered
}

// Read in the how-to content and substitute variables
data "template_file" "home_page_content" {
  template = file("${path.module}/home_page_content.md")
  vars = {
    create_new_requirements_work_item_url = azuredevops_workitem.create_new_requirements_work_item.id
    review_work_item_url                  = azuredevops_workitem.requirements_review_work_item.id
    create_design_work_item_url           = azuredevops_workitem.create_new_design_work_item.id
    design_work_item_url                  = azuredevops_workitem.design_work_item.id
    create_plan_work_item_url             = azuredevops_workitem.create_plan_work_item.id
  }
}


