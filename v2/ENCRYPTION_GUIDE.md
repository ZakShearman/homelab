# Encryption Guide
Files that contain sensitive credentials have their creds extracted and stored using SOPS and age

The private key should be stored in your ~/.config/sops/age/keys.txt file

## Encrypt a File
```
sops -e --age age17wchejr0w9vs3stn4y3shenyq8urn668mqc642nn7d4rrd29j4ss02e4nq input.yaml > output.enc.yaml
```

## Decrypt a File
```
sops -d input.enc.yaml > output.yaml
```