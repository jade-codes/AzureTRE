locals {
  shared_image_gallery_name     = "${var.tre_id}_vm_imagegallery"
  software_storage_account_name = lower(replace("stsft${var.tre_id}", "-", ""))

  security_control_tags = merge(
    var.tre_core_tags,
    {
      "CostControl"     = "Ignore"
      "SecurityControl" = "Ignore"
    }
  )
}
