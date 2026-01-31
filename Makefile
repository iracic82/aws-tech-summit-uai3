.PHONY: init plan apply destroy fmt validate clean

TERRAFORM_DIR := terraform

init:
	cd $(TERRAFORM_DIR) && terraform init

plan: init
	cd $(TERRAFORM_DIR) && terraform plan

apply: init
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

fmt:
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

validate: init
	cd $(TERRAFORM_DIR) && terraform validate

output:
	cd $(TERRAFORM_DIR) && terraform output

clean:
	rm -rf $(TERRAFORM_DIR)/.terraform
	rm -f $(TERRAFORM_DIR)/*.tfstate*
	rm -f $(TERRAFORM_DIR)/*.pem
	rm -f $(TERRAFORM_DIR)/*.tfplan
