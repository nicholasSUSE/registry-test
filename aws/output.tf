output "workload_1_ip" {
  value = module.ec2_instance.instance_public_ip
}
output "workload_1_dns" {
  value = module.ec2_instance.instance_dns
}
output "debug_workload_1" {
  value = module.ec2_instance.debug_instance
}
