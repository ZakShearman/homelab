# Manifest
A manifest of what I run in my Homelab at current.

## Hardware

Networking:
- Unifi Express
- Unifi Lite 16 PoE Switch
- Unifi  U6+
- Unifi U6 In-Wall

Hosts:
- 1x [BOSGAME Ryzen 7 Mini PC 5700U, 32GB](https://www.amazon.co.uk/dp/B0CQLXMHTB)

## Software

My hosts run in a Proxmox cluster which runs a Talos Kubernetes cluster on top.
All infrastructure is managed by Terraform.

## Services

- MetalLB - Bare metal load balancer, used for ingress on local IPs.
- Longhorn - Distributed block storage.
