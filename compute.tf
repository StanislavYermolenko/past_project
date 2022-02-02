resource "google_compute_instance" "vm_instance" {
  name         = var.name
  machine_type = var.type
  project      = var.PROJECT_ID
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-8"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.network-with-private-secondary-ip-ranges.id
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }


  metadata_startup_script = "${data.template_file.init.rendered}"

  provisioner "remote-exec" {
    inline = ["hostname"]

     connection {
       host	   = "${google_compute_address.static.address}"
       type        = "ssh"
       user        = "${var.SSH_USER}"
       private_key = "${file(var.FULL_PR_KEYS_PATH)}"
     }
  } 

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.SSH_USER} -i '${google_compute_address.static.address},' --private-key ${var.FULL_PR_KEYS_PATH} playbook.yml"
  }
}


data "template_file" "init" {
  template = "${file("${path.module}/start.tpl")}"
  vars = {
    app_ip    = "${google_compute_address.static.address}"
    slack_wh  = var.SLACK_WH
    # sl_channel = var.SLACK_CHANNEL
    SLACK_BUG = var.SLACK_BUG
    SLACK_US  = var.SLACK_US
    SLACK_TC  = var.SLACK_TC
  }
}



output "app_ip" {
  value = "${google_compute_address.static.address}"
}

