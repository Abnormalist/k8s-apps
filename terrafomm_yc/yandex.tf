terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.token_val
  cloud_id  = var.cloud_id_val
  folder_id = var.folder_id_val
  zone      = var.zone_val
}

#=======K8S MASTER VM-1==========#
resource "yandex_compute_instance" "vm-1" {
  name = "k8s-master"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8kdnltr2353cirte81"
      size     = "13"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {   
    #user-data = "${file("user-data.txt")}"       
    ssh-keys = "debian-11:${file("~/.ssh/id_ed25519.pub")}"
  }
  
  connection {
    type        = "ssh"
    user        = "debian"
    #password = var.root_password
    private_key = "${file("~/.ssh/id_ed25519")}"
    host        = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
  } 
# Copy script to remote vm
  provisioner "file" {
    source      = "k8s-kind.sh"
    destination = "/tmp/k8s-kind.sh"
  }
# Execute scripts on remote vm  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/k8s-kind.sh",
      "/tmp/k8s-kind.sh",
    ]
  }

}

##=======K8S WORKER VM-2==========#
#resource "yandex_compute_instance" "vm-2" {
#  name = "k8s-worker"
#
#  resources {
#    cores  = 2
#    memory = 4
#  }
#
#  boot_disk {
#    initialize_params {
#      image_id = "fd8kdnltr2353cirte81"
#      size     =
#    }
#  }
#
#  network_interface {
#    subnet_id = yandex_vpc_subnet.subnet-1.id
#    nat       = true
#  }
#
#  metadata = {
#    #user-data = "${file("user-data.txt")}" 
#    ssh-keys = "debian-11:${file("~/.ssh/id_ed25519.pub")}"
#  }
#}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
#resource "yandex_alb_target_group" "k8s-kind" {
#  name      = "k8s-kind-group"

#  target {
#    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
#    ip_address   = "${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
#  }
#}

#=======HTTP ALB ROUTER=======#
#resource "yandex_alb_http_router" "tf-router" {
#  name      = "my-http-router"
#  folder_id = var.folder_id_val
#  labels = {
#    tf-label    = "tf-label-value"
#    empty-label = ""
#  }
#}

#=======LOAD BALANCER=========#
#resource "yandex_alb_load_balancer" "test-balancer" {
#  name        = "my-load-balancer"

#  network_id  = yandex_vpc_network.network-1.id

#  allocation_policy {
#    location {
#      zone_id   = "ru-central1-a"
#      subnet_id = yandex_vpc_subnet.subnet-1.id 
#    }
#  }

#  listener {
#    name = "my-listener"
#    endpoint {
#      address {
#        external_ipv4_address {
#        }
#      }
#      ports = [ 80,443 ]
#    }    
#    http {
#      handler {
#        http_router_id = yandex_alb_http_router.tf-router.id
#      }
#    }
#  }   
#}

