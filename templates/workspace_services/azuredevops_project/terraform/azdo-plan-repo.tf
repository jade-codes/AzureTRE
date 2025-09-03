// Create a repo and wiki for project plans.

// Create a new git repository for storing project plans. Under TQL 4/5,
// plans need change management, so we use a wiki repo pull-request process.
resource "azuredevops_git_repository" "plan_git_repo" {
  project_id     = azuredevops_project.project.id
  name           = "Plans"
  default_branch = "refs/heads/main"
  initialization {
    init_type = "Clean"
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
