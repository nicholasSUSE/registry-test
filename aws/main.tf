module "ec2_instance" {
  source = "./ec2"

  # Pass any required variables to the module
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_session_token     = var.aws_session_token
  aws_region            = var.aws_region
  instance_type         = var.instance_type
  user                  = var.user
  prefix                = var.prefix
}

resource "null_resource" "download_certificate" {
  depends_on = [module.ec2_instance]

  provisioner "local-exec" {
    command = <<-EOT
      timeout 5m scp -o StrictHostKeyChecking=no -v -i ./certs/id_rsa ubuntu@${module.ec2_instance.instance_dns}:/etc/docker/certs.d/${module.ec2_instance.instance_dns}/domain.crt ./certs/domain.crt
    EOT
  }
}
