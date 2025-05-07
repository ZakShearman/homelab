data "sops_file" "secrets" {
  source_file = "${path.module}/files/secrets.enc.yaml"
}

data "sops_file" "cloudflare_tunnel" {
  source_file = "${path.module}/files/cloudflare-tunnel-creds.enc.json"
}