locals {
  shared_image_gallery_name     = "${var.tre_id}_vm_imagegallery"
  software_storage_account_name = lower(replace("stsft${var.tre_id}", "-", ""))
}
