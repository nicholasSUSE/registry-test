resource "aws_instance" "instance" {
  depends_on = [
    aws_route_table_association.route_table_association
  ]

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.sg_allowall.id]
  subnet_id                   = aws_subnet.subnet.id
  associate_public_ip_address = true

  # Instance HD size
  root_block_device {
    volume_size = 30
    tags = {
      "Name" = "${var.prefix}-${var.user}-volume"
    }
  }

  # upload files
  provisioner "file" {
    source      = "./compose/docker-compose.yml"
    destination = "/home/ubuntu/docker-compose.yml"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "./compose/registry-config.yml"
    destination = "/home/ubuntu/registry-config.yml"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "./compose/prometheus.yml"
    destination = "/home/ubuntu/prometheus.yml"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  # execute scripts on the newly created instance.
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  # configure docker and a self-signed certificate on it
  user_data = <<-EOF
${templatefile("${path.root}/scripts/docker_config.template", {})}
${templatefile("${path.root}/scripts/tls_config.template", {})}
EOF

  tags = {
    Name    = "${var.prefix}-${var.user}-instance"
    Creator = var.user
  }
}


output "instance_public_ip" {
  description = "The public IP of the workload 1 instance"
  value       = aws_instance.instance.public_ip
}
output "instance_dns" {
  description = "The public DNS of the workload 1 instance"
  value       = aws_instance.instance.public_dns
}
output "debug_instance" {
  value = "ssh -i ./aws/certs/id_rsa ubuntu@${aws_instance.instance.public_dns}"
}