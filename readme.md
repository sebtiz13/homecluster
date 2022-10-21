# Setup repository

This repository contains :

- vagrant config for local testing
- terraform file for provisioning clusters

## Vagrant

Default domain : `local.vm`

### Requirement

For use environment please install :

- [mkcert](https://github.com/FiloSottile/mkcert)

### Usage

To create or recreate VMs you can use follow command

```sh
make vagrant
```

And if you want create only one VM you can pass `salamandre.vm` ou `baku.vm` in the command. e.g. command

```sh
make vagrant VM_NAME=salamandre.vm
```

#### Vagrant variables

- `VM_NAME` (valid values: `salamandre.vm`, `baku.vm`): The vm name for only create on

## Terraform

### Variables

- `SERVER` (**REQUIRED**, valid values: `salamandre`, `baku`): The server want used for deploy
- `ARGS`: The args want be pass to terraform (eg. `ARGS="--target='module.ssh'"`)

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

## GitLab Agent

Deploy the GitLab Agent for Kubernetes (agentk) with the following command

```sh
./gitlab-agent.sh <token>
```

**NOTE**: For deploy on vagrant cluster specify `ENVIRONMENT` to `vm`
