resource "vsphere_content_library" "library" {
  name            = var.no_access_vcenter.vcenter.contentLibrary.name
  storage_backing = [data.vsphere_datastore.datastore.id]
  description     = var.no_access_vcenter.vcenter.contentLibrary.description
}

//resource "vsphere_content_library_item" "files" {
//  count = length(var.contentLibrary.files)
//  name        = basename(element(var.contentLibrary.files, count.index))
//  description = basename(element(var.contentLibrary.files, count.index))
//  library_id  = vsphere_content_library.library.id
//  file_url = element(var.contentLibrary.files, count.index)
//}

resource "vsphere_content_library_item" "avi" {
  name        = "Avi OVA file"
  description = "Avi OVA file"
  library_id  = vsphere_content_library.library.id
  file_url = var.no_access_vcenter.vcenter.contentLibrary.aviOvaFile
}

resource "vsphere_content_library_item" "ubuntu" {
  name        = "Ubuntu OVA file"
  description = "Ubuntu OVA file"
  library_id  = vsphere_content_library.library.id
  file_url = var.no_access_vcenter.vcenter.contentLibrary.ubuntuOvaFile
}