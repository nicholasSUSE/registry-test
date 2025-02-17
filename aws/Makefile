clean:
	clear
	terraform destroy --auto-approve || true
	rm -Rf .terraform || true
	rm .terraform.lock.hcl || true
	rm terraform.tfstate* || true

run:
	terraform init -reconfigure && terraform apply --auto-approve
