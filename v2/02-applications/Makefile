decrypt:
	sops -d files/secrets.enc.yaml > files/secrets.yaml

plan:
	tofu plan -var-file=homelab.tfvars

planshowsensitive:
	tofu plan -var-file=homelab.tfvars --show-sensitive

apply:
	tofu apply -var-file=homelab.tfvars

