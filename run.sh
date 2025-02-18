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

    echo "Type any user/password; this is a dummy login!"
    docker login $INSTANCE_DNS

    assets_path="./oci-test/assets"
    assets_dir=($(find "$assets_path" -maxdepth 1 -type d -print0 | xargs -0))

    for dir in "${assets_dir[@]}"; do
        # Get the list of files and store it in an array
        files_array=($(find "$dir" -maxdepth 1 -type f -print0 | xargs -0))
        # Loop through the array of files
        for file in "${files_array[@]}"; do
            helm push $file oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
        done
    done

    echo "List Repos on OCI Registry"
    curl -X GET https://$INSTANCE_DNS/v2/_catalog --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt --insecure
}


function checkRegistry() {
    cd $WORK_DIR
    curl -X GET https://$INSTANCE_DNS/v2/fleet/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/fleet-crd/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/fleet-agent/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'


    curl -X GET https://$INSTANCE_DNS/v2/rancher-logging/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/rancher-logging-crd/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/rancher-monitoring/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/rancher-monitoring-crd/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/sriov/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/sriov-crd/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'

    curl -X GET https://$INSTANCE_DNS/v2/_catalog --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt | \
    jq '.tags | sort'
}

function helper() {
    cd $WORK_DIR

    # Disable command logging
    set +x

    echo -e "________________________________________________________\n"
    echo -e "TLS Docker registry setup complete\n"

    echo -e "INSTANCE_DNS=$INSTANCE_DNS \n"

    echo "2. List repositories"
    echo "if without certificate add --insecure in the end of the command"
    echo -e "curl -X GET https://\$INSTANCE_DNS/v2/_catalog --cacert /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt \n"

    echo "3. List tags (versions)"
    echo "curl -X GET https://\$INSTANCE_DNS/v2/<repository-name>/tags/list --cacert /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt \n"

    echo "4. Push an image"
    echo "if without certificate add --insecure-skip-tls-verify in the end of the command"
    echo -e "helm push ./oci-test/assets/fleet/fleet-104.0.0+up0.10.0.tgz oci://\$INSTANCE_DNS --ca-file /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt \n"

    echo "5. Pull an image"
    echo -e "helm pull oci://\$INSTANCE_DNS/fleet:104.0.0+up0.10.0 --ca-file /etc/docker/certs.d/\$INSTANCE_DNS/ca.crt --debug \n"

    sudo openssl x509 -outform der -in /etc/docker/certs.d/$INSTANCE_DNS/ca.crt -out /etc/docker/certs.d/$INSTANCE_DNS/ca.der
    base64 -w 0 /etc/docker/certs.d/$INSTANCE_DNS/ca.der > /etc/docker/certs.d/$INSTANCE_DNS/ca_der_base64.txt

    cd $AWS_DIR
    debug=$(terraform output debug_workload_1)
    echo "To debug AWS EC2 instance, run the following command"
    echo $debug

    echo "To Create the OCI Registry in Rancher, Run/copy/paste the CA Cert Bundle at Rancher: "
    echo -e "cat /etc/docker/certs.d/$INSTANCE_DNS/ca_der_base64.txt | xclip -selection clipboard \n"
    echo -e "oci://$INSTANCE_DNS \n"

    echo "Access prometheus metrics: "
    echo -e "http://$INSTANCE_DNS:9090 \n"

    cd $WORK_DIR

    # Re-enable command logging
    set -x
}


setupGIT
initTerraform
tls_docker
setupRegistry
checkRegistry
helper