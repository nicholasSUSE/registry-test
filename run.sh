#!/bin/bash

set -x
# Global Variables
INSTANCE_DNS=""
WORK_DIR=$(pwd)
OCI_DIR="$WORK_DIR/oci-test"
AWS_DIR="$WORK_DIR/aws"

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

cd $AWS_DIR
./aws-registry.sh || { echo "./aws-registry.sh failed"; exit 1; } # Crucial change!

# Get the instance DNS from Terraform output
INSTANCE_DNS=$(terraform output -raw workload_1_dns)
cd $WORK_DIR

docker login $INSTANCE_DNS

echo "List Repos on OCI Registry"
curl -X GET https://$INSTANCE_DNS/v2/_catalog --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt --insecure

echo "List tags (versions)"
echo "curl -X GET https://$INSTANCE_DNS/v2/<repository-name>/tags/list --cacert /etc/docker/certs.d/$INSTANCE_DNS/ca.crt --insecure"


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
