output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

#output "internal_ip_address_vm_2" {
#  value = yandex_compute_instance.vm-2.network_interface.0.ip_address
#}


output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

#output "external_ip_address_vm_2" {
#  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
#}

#output "alb_http_router" {
#  value = yandex_alb_http_router.tf-router.id
#}
#output "load_balancer" {
#  value = yandex_alb_load_balancer.test-balancer.listener[0.0]
#}