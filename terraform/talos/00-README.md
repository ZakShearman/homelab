Run the terraform (tf init, tf apply, yes)

```bash
terraform output -raw kubeconfig > ../../kubeconfig
terraform output -raw talosconfig > ../../talosconfig
```