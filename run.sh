#!/bin/bash

set -x
# Global Variables
INSTANCE_DNS=""
WORK_DIR=$(pwd)
OCI_DIR="$WORK_DIR/oci-test"
AWS_DIR="$WORK_DIR/aws"

function setupGIT() {
    # check if it is empty and clone the repo
    if [ -z "$(ls -A oci-test)" ]; then
        git clone git@github.com:nicholasSUSE/oci-test.git
    else
        echo "The folder 'oci-test' is not empty."
        cd $OCI_DIR
        git fetch
        git pull
    fi

    cd $WORK_DIR
    ls -lah $OCI_DIR
}

function initTerraform() {
    cd $AWS_DIR
    # Destroy
    terraform destroy --auto-approve || true
    rm -Rf .terraform || true
    rm certs/* || true
    # Reset
    terraform init -reconfigure
    terraform apply --auto-approve

    # Check if the instance is reachable using ping
    INSTANCE_DNS=$(terraform output -raw workload_1_dns)
    if !ping -c 1 "$INSTANCE_DNS" >/dev/null 2>&1; then
        echo "Failed to ping instance: $INSTANCE_DNS"
        exit 1
    else
        echo "Successfully pinged instance: $INSTANCE_DNS"
    fi

    cd $WORK_DIR
    ls -lah $AWS_DIR
}

function tls_docker() {
    cd $AWS_DIR

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

    cd $WORK_DIR
    ls -lah $AWS_DIR
}

function setupRegistry() {
    # Get the instance DNS from Terraform output
    cd $WORK_DIR

    docker login $INSTANCE_DNS
    set +x

    directory="./oci-test/assets/fleet"

    # Get the list of files and store it in an array
    files_array=($(find "$directory" -maxdepth 1 -type f -print0 | xargs -0))

    # Loop through the array of files
    for file in "${files_array[@]}"; do
        helm push $file oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt --insecure-skip-tls-verify
    done

    echo "List Repos on OCI Registry"
    curl -X GET https://$INSTANCE_DNS/v2/_catalog --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt --insecure

    echo "List tags (versions)"
    echo "curl -X GET https://$INSTANCE_DNS/v2/<repository-name>/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt --insecure"
    set -x
}






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


setupGIT
initTerraform
tls_docker
setupRegistry