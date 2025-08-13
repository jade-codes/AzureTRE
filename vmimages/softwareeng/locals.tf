locals {
  shared_image_gallery_name = "${var.tre_id}_vm_imagegallery"

  tre_core_tags = {
    tre_id              = var.tre_id
    tre_core_service_id = var.tre_id
    tre_image_build     = "softwareeng"
  }
}
