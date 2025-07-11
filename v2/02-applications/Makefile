decrypt:
	sops -d files/secrets.enc.yaml > files/secrets.yaml

encrypt:
	sops -e --age age17wchejr0w9vs3stn4y3shenyq8urn668mqc642nn7d4rrd29j4ss02e4nq files/secrets.yaml > files/secrets.enc.yaml

plan:
	tofu plan -var-file=homelab.tfvars

planshowsensitive:
	tofu plan -var-file=homelab.tfvars --show-sensitive

apply:
	tofu apply -var-file=homelab.tfvars

