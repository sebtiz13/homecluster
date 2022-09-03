# Setup repository

This repository contains :

- vagrant config for local testing
- terraform file for provisioning clusters

## Vagrant

To create or recreate VMs you can use follow command

```sh
make vagrant
```

And if you want create only one VM you can pass `salamandre.vm` ou `baku.vm` in the command. e.g. command

```sh
make vagrant VM_NAME=salamandre.vm
```

### Vagrant variables

- `VM_NAME` (valid values: `salamandre.vm`, `baku.vm`): The vm name for only create on

## Terraform

### Production

To provide cluster you can use follow command

```sh
make cluster
```

### Testing

To provide cluster you can use follow command

```sh
make test-cluster
```

**NOTE**: You can also provide [arguments from `vagrant` command](#vagrant-variables) (eg. `make test-cluster VM_NAME=salamandre.vm`)
