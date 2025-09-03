// Create a default code repository for the project.
// This will hold any scripts and pipelines needed for the project.

resource "azuredevops_git_repository" "default_git_repo" {
  project_id     = azuredevops_project.project.id
  name           = "Code"
  default_branch = "refs/heads/main"
  initialization {
    init_type = "Clean"
  }
}

// Add the pipeline files to the default repository.
resource "azuredevops_git_repository_file" "pipeline_files" {
  for_each = toset([
    ".azdo/validation-pipeline.yml",
    ".azdo/Validate-LinkedWorkItems.ps1",
  ])

  repository_id       = azuredevops_git_repository.default_git_repo.id
  branch              = azuredevops_git_repository.default_git_repo.default_branch
  file                = each.value
  content             = file("${path.module}/resources/${basename(each.value)}")
  commit_message      = "Add initial pipeline configuration."
  overwrite_on_create = false

  lifecycle {
    // Once created, we can't update it as we will have applied branch
    // policies preventing further commits.
    ignore_changes = all
  }
}

// Create a build pipeline to validate traceability on pull requests.
resource "azuredevops_build_definition" "default_repo_validation_check_pipeline" {
  project_id = azuredevops_project.project.id
  name       = "Validate Traceability on PR"

  # This pipeline needs to depend on the file being created to ensure it exists.
  depends_on = [azuredevops_git_repository_file.pipeline_files]

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.default_git_repo.id
    branch_name = azuredevops_git_repository.default_git_repo.default_branch
    yml_path    = "/.azdo/validation-pipeline.yml"
  }
}

// Ensure the validation pipeline is run on pull requests to the main branch.
resource "azuredevops_branch_policy_build_validation" "default_repo_build_validation_policy" {
  project_id = azuredevops_project.project.id
  enabled    = true
  blocking   = true

  # These files needs to be created before the policy can be applied.
  depends_on = [azuredevops_git_repository_file.pipeline_files]

  settings {
    display_name                = "Ensure Traceability"
    build_definition_id         = azuredevops_build_definition.default_repo_validation_check_pipeline.id
    queue_on_source_update_only = true
    valid_duration              = 720

    scope {
      repository_id  = azuredevops_git_repository.default_git_repo.id
      repository_ref = azuredevops_git_repository.default_git_repo.default_branch
      match_type     = "Exact"
    }
  }
}

// Create a branch policy to ensure that work items are linked to commits / PRs.
// More thorough validation is done in the validation pipeline.
resource "azuredevops_branch_policy_work_item_linking" "default_git_repo_work_item_linking_policy" {
  project_id = azuredevops_project.project.id
  enabled    = true
  blocking   = true

  # These file need to be created before the policy can be applied.
  depends_on = [azuredevops_git_repository_file.pipeline_files]

  settings {
    scope {
      repository_id  = azuredevops_git_repository.default_git_repo.id
      repository_ref = azuredevops_git_repository.default_git_repo.default_branch
      match_type     = "Exact"
    }
  }
}

// Create a branch policy to ensure that comments on PRs are resolved.
resource "azuredevops_branch_policy_comment_resolution" "default_git_repo_comment_resolution_policy" {
  project_id = azuredevops_project.project.id
  enabled    = true
  blocking   = true

  # These file need to be created before the policy can be applied.
  depends_on = [azuredevops_git_repository_file.pipeline_files]

  settings {
    scope {
      repository_id  = azuredevops_git_repository.default_git_repo.id
      repository_ref = azuredevops_git_repository.default_git_repo.default_branch
      match_type     = "Exact"
    }
  }
}

// Create a branch policy for the plans repo to ensure a pull-request workflow.
resource "azuredevops_branch_policy_min_reviewers" "default_git_repo_reviewers_policy" {
  project_id = azuredevops_project.project.id
  enabled    = true
  blocking   = true

  # These file need to be created before the policy can be applied.
  depends_on = [azuredevops_git_repository_file.pipeline_files]

  settings {
    reviewer_count = 1

    scope {
      repository_id  = azuredevops_git_repository.default_git_repo.id
      repository_ref = azuredevops_git_repository.default_git_repo.default_branch
      match_type     = "Exact"
    }
  }
}
