locals {
  version                          = "1-0-0"
  software_eng_resource_group_name = "rg-${var.tre_id}-vm-build-software-eng"
  shared_image_gallery_name        = "${var.tre_id}_vm_imagegallery"
  software_storage_account_name    = lower(replace("stsft${var.tre_id}", "-", ""))

  software_eng_identity_name    = "${var.tre_id}-vm-build-software-eng-image-builder-id"
  software_eng_vm_identity_name = "${var.tre_id}-vm-build-software-eng-image-builder-vm-id"

  software_eng_win_template_name = "${var.tre_id}-vm-build-software-eng-win-template-${local.version}"

  builder_subnet_name = "VMImageBuildSubnet"
  builder_vnet_name   = "vnet-${var.tre_id}"

  software_storage_url_prefix = "https://${local.software_storage_account_name}.blob.core.windows.net/installers/"

}
