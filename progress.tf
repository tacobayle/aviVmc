
resource "null_resource" "content_library" {
  depends_on = [vsphere_content_library.library, vsphere_content_library_item.avi, vsphere_content_library_item.ubuntu]
}

resource "null_resource" "vm" {
  depends_on = [vsphere_virtual_machine.controller, vsphere_virtual_machine.jump]
}

resource "null_resource" "avi_config" {
  depends_on = [null_resource.ansible]
}