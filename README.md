## Objective

Automate the deploy of an EC2 AWS instance with a basic OCI Registry signing it with a self-signed CA.

### Needed packages

- terraform
- gcr
- jq
- docker


### How-to

#### Deploy EC2 Instance with self-signed certificate

1. Get your credentials on `aws/terraform.tfvars`:

  ```
  aws_access_key_id=""
  aws_secret_access_key=""
  aws_session_token=""
  ```

2. Configure your aws zone; prefix and etc... at `aws/terraform.tfvars`:

  ```
  user = "#####" (you choose)
  prefix = "####" (you choose)
  aws_region = "us-east-2"
  aws_zone = "us-east-2a"
  instance_type = "t3a.2xlarge"
  ```

3. Run `run.sh` with sudo

  Beware this will erase all your local docker configurations!
  Check `tls_docker` function at `run.sh`
  ```
  sudo ./run.sh
  ```

#### Configure your dev environment to the OCI Registry with the self-signed certificate

4. Run after the previous step:

  ```
  ./local_config.sh
  ```

> <workload_1_dns> is defined at `aws/output.tf` is the dynamic public dns created at a new instance. It is automatically calculated at local_config.sh script

---

#### Oci registry with Docker

```
docker login <workload_1_dns>
docker tag <chart>:latest <workload_1_dns>/<chart>:latest
docker push <workload_1_dns>/<chart>:latest
docker pull <workload_1_dns>/<chart>:latest
curl -X GET https://<workload_1_dns>:5000/v2/_catalog --cacert /etc/docker/certs.d/<workload_1_dns>/ca.crt
curl -X GET http://<workload_1_dns>:5000/v2/<chart>/tags/list --cacert /etc/docker/certs.d/<workload_1_dns>/ca.crt
```

#### Oci registry with Helm

```
helm registry login <workload_1_dns>
helm push <path_to_asset_.tgz> oci://<workload_1_dns> --ca-file /etc/docker/certs.d/<workload_1_dns>/ca.crt
helm pull oci://<workload_1_dns>/<chart>>:<tag> --ca-file /etc/docker/certs.d/<workload_1_dns>/ca.crt
```

##### Caveat

```
» helm push ../assets/rancher-istio/rancher-istio-104.2.0+up1.20.3.tgz oci://$PUBLIC_DNS --ca-file /etc/docker/certs.d/$PUBLIC_DNS/ca.crt

Pushed: ec2-3-144-42-54.us-east-2.compute.amazonaws.com/rancher-istio:104.2.0_up1.20.3
Digest: sha256:fa8c5ee6896cb578ded34033701f4700f346ce3dc86b09aeec5b34f75ba4d428
ec2-3-144-42-54.us-east-2.compute.amazonaws.com/rancher-istio:104.2.0_up1.20.3 contains an underscore.

OCI artifact references (e.g. tags) do not support the plus sign (+). To support
storing semantic versions, Helm adopts the convention of changing plus (+) to
an underscore (_) in chart version tags when pushing to a registry and back to
a plus (+) when pulling from a registry.
```

##### Backup

```
helm push ../assets/rancher-istio/rancher-istio-104.2.0+up1.20.3.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/rancher-istio/rancher-istio-104.3.0+up1.21.1.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/rancher-istio/rancher-istio-104.4.0+up1.22.1.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt

helm push ../assets/rancher-gatekeeper/rancher-gatekeeper-101.0.0+up3.9.0.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/rancher-gatekeeper/rancher-gatekeeper-102.1.2+up3.13.0.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/rancher-gatekeeper/rancher-gatekeeper-104.0.0+up3.13.0.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt

helm push ../assets/longhorn/longhorn-101.2.0+up1.4.0.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/longhorn/longhorn-102.2.0+up1.4.1.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/longhorn/longhorn-102.4.0+up1.6.1.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/longhorn/longhorn-103.0.0+up1.3.3.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/longhorn/longhorn-103.1.0+up1.4.3.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
helm push ../assets/longhorn/longhorn-104.1.0+up1.6.2.tgz oci://$INSTANCE_DNS --ca-file /etc/docker/certs.d/$INSTANCE_DNS/ca.crt
```

---

### Rancher Ngrok Debugging(legacy)

1. `terraform init && terraform apply --auto-approve`
2. `k3d cluster create local`
3. `Debug Rancher`
4. `ngrok http --domain=boss-polite-seasnail.ngrok-free.app https://localhost:8443`
5. Login to Rancher defining: `https://boss-polite-seasnail.ngrok-free.app` as the main URL
6. Cluster Management > Create Cluster
7. Copy `insecure` command inside EC2 instance and execute it.


#### Ngrok

My ngrok domain:
```
ngrok http --domain=boss-polite-seasnail.ngrok-free.app 80
```

How to: https://ngrok.com/blog-post/free-static-domains-ngrok-users

Ngrok Command:
```
ngrok http --domain=boss-polite-seasnail.ngrok-free.app https://localhost:8443

```

https://aws.amazon.com/ec2/instance-types/

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.27.4+k3s1	 sh -s - server --cluster-init
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.25.4+k3s1	 sh -s - server --cluster-init


sudo journalctl -xeu k3s -f | grep kube-apiserver
