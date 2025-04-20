# Deployment

## Setup Documentation

### Create pull secrets GitHub for Kubernetes

- set env `CR_PAT` (you can create the token here: https://github.com/settings/tokens)
- `kubectl create secret docker-registry github-container-registry --namespace=default --docker-server=ghcr.io --docker-username=philipp-lein --docker-password=${CR_PAT} --dry-run=client --output=yaml > docker-secret.yaml`

### Create new ssh private and public key

- `ssh-keygen -t rsa -b 4096 -C ssh_private_key`

### Update cert-manager

- download cert-manager file from here https://cert-manager.io/docs/installation/#default-static-install


### HOTFIX FOR actual PROBLEMS 
`kubectl apply --server-side --force-conflicts -k https://github.com/traefik/traefik-helm-chart/traefik/crds/`
`kubectl rollout restart deployment traefik -n kube-system`


### Things to come:
#### new loadbalancer modus with hetzner cloud-controller
install cluster with 
curl -sfL https://get.k3s.io | sh -s - server \
	--cluster-init \
    --disable-cloud-controller \
    --disable local-storage \
    --node-name="$(hostname -f)" \
    --kubelet-arg="cloud-provider=external" 

install hetzner token secret
install cloud-controller-manager with helm
helm repo add hcloud https://charts.hetzner.cloud
helm install hccm hcloud/hcloud-cloud-controller-manager -n kube-system
follow https://ellie.wtf/notes/hetzner-k3s