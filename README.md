# iac-foundry

Deploy Foundry to a Kubernetes Cluster

## Instructions

1. Clone the repo `git clone git@github.com:boop-ninja/iac-foundry.git`
2. Create a `terraform.tfvars.json` file
3. Add the following contents to the file

   ```json
   {
     "kube_host": "https://your.kube.host:6443",
     "kube_crt": "your-kube-crt",
     "kube_key": "your-kube-key"
   }
   ```

4. Run a `terraform init`
5. Change the workspace to be the domain you wish to deploy to, ex: `dnd.example.com`

   ```sh
   terraform workspace new dnd.example.com
   ```

6. Run a `terraform plan` and review that it is acceptable
7. If acceptable run `terraform apply -y`
8. Add two CNAME records to point to your root (if your root domain is pointing to your cluster)
9. If not, add two A records to point to your cluster.

### Records to add

dnd.example.com
dnd-admin.example.com

## Outcome

It creates two containers with two services:

- Foundry container at https://dnd.exampe.com
- Syncthing at https://dnd-admin.example.com

## What to do next

1. Access your foundry server and follow the setup instructions.
2. [Install Syncthing](https://syncthing.net/) locally and add your foundry server.
3. Secure your syncthing instance.
4. Secure your foundry instance.
