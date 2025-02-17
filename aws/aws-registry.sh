#!/bin/bash

set -x


# Declare INSTANCE_DNS as a global variable
INSTANCE_DNS=""

function tf() {
	terraform destroy --auto-approve || true
	rm -Rf .terraform || true
	rm .terraform.lock.hcl || true
	rm terraform.tfstate* || true
  terraform init -reconfigure
  terraform apply --auto-approve

  # Get the instance DNS from Terraform output
  INSTANCE_DNS=$(terraform output -raw workload_1_dns)

  if [ -z "$INSTANCE_DNS" ]; then
    echo "Failed to retrieve instance DNS from Terraform output"
    exit 1
  fi

  echo "Instance DNS: $INSTANCE_DNS"
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


function helper() {
  # Disable command logging
  set +x

  echo -e "________________________________________________________\n"
  echo -e "TLS Docker registry setup complete\n"

  echo -e "INSTANCE_DNS=$INSTANCE_DNS\n"

  echo -e "Next steps: \n"
  echo "1. Log in to Docker"
  echo -e "docker login \$INSTANCE_DNS \n"

  echo "2. List repositories"
  echo -e "curl -X GET https://\$INSTANCE_DNS/v2/_catalog --cacert /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt --insecure \n"

  echo "3. List tags (versions)"
  echo "curl -X GET https://\$INSTANCE_DNS/v2/<repository-name>/tags/list --cacert /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt --insecure \n"

  echo "4. Push an image"
  echo -e "helm push ../assets/rancher-istio/rancher-istio-104.2.0+up1.20.3.tgz oci://\$INSTANCE_DNS --ca-file /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt --insecure-skip-tls-verify \n"

  echo "5. Pull an image"
  echo -e "helm pull oci://\$INSTANCE_DNS/rancher-istio:104.2.0+up1.20.3 --ca-file /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt --insecure-skip-tls-verify --debug \n"

  # Re-enable command logging
  set -x
}



tf
tls_docker
helper
