#!/bin/bash

set -x

INSTANCE_DNS=$(terraform output -raw workload_1_dns)

function destroy() {
	terraform destroy --auto-approve || true
	rm -Rf .terraform || true
	rm .terraform.lock.hcl || true
	rm terraform.tfstate* || true
}

function init() {
  terraform init -reconfigure
  terraform apply --auto-approve
  # Check if the instance is reachable using ping
  if !ping -c 1 "$INSTANCE_DNS" >/dev/null 2>&1; then
    echo "Failed to ping instance: $INSTANCE_DNS"
    exit 1
  else
    echo "Successfully pinged instance: $INSTANCE_DNS"
  fi
}

function tls_docker() {
  sudo rm /etc/docker/daemon.json
  sudo touch /etc/docker/daemon.json
  echo '{"insecure-registries": ["'"$INSTANCE_DNS"'"]}' | sudo tee /etc/docker/daemon.json

  # Create the directory for the registry certificate
  sudo rm -rf /etc/docker/certs.d/*
  sudo mkdir -p /etc/docker/certs.d/$INSTANCE_DNS

  # Copy the certificate to the Docker certs directory
  sudo cp ./certs/domain.crt /etc/docker/certs.d/$INSTANCE_DNS/ca.crt

  ls ./certs/domain.crt /etc/docker/certs.d/$INSTANCE_DNS/

  # Restart Docker to apply the changes
  sudo systemctl restart docker
}




destroy
init
tls_docker
