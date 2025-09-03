// Create a project wiki to hold documentation and how-to guides.

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
  template = file("${path.module}/resources/home_page_content.md")
  vars = {
    create_new_requirements_work_item_url = azuredevops_workitem.create_new_requirements_work_item.id
    review_work_item_url                  = azuredevops_workitem.requirements_review_work_item.id
    create_design_work_item_url           = azuredevops_workitem.create_new_design_work_item.id
    design_work_item_url                  = azuredevops_workitem.design_work_item.id
    create_plan_work_item_url             = azuredevops_workitem.create_plan_work_item.id
  }
}
