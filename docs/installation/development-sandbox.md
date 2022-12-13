# Development sandbox

The sandbox is intended for trying out the cluster without any hardware or testing changes before applying them to the
production environment.

The local cluster have `local.vm` as base domain but this can be changed by passing `DOMAIN_NAME` environment variable.

## Prerequisites

### Host machine

- recommended hardware specifications:

  - CPU: 8 cores
  - RAM: 24 GiB

- OS: Linux

### Install the following packages

- [Make](https://www.gnu.org/software/make/)
- [Vagrant](https://www.vagrantup.com/)
  - [libvirt](https://libvirt.org/)
- [mkcert](https://github.com/FiloSottile/mkcert)
- [Helm](https://helm.sh/)
- [Ansible](https://www.ansible.com/)
  - [yq](https://github.com/mikefarah/yq/)

### Configuring DNS

#### With `dnsmasq` (**recommended**)

Create an config file with `dnsmasq` (in `/etc/NetworkManager/dnsmasq.d/<name>.conf` or in `/etc/dnsmasq.conf`) with this following values:

```conf
local=/vm/
address=/.local.vm/192.168.12.10
address=/baku.local.vm/192.168.12.11
```

> **NOTE**: you can follow this tutorial for setup `dnsmasq` with `NetworkManager` : [Using the NetworkManager’s DNSMasq plugin - fedoramagazine.org](https://fedoramagazine.org/using-the-networkmanagers-dnsmasq-plugin/)

#### With `/etc/hosts`

Add the following line in `/etc/hosts` file:

```conf
192.168.12.10 local.vm argocd.local.vm vault-secrets.local.vm sso.local.vm s3.local.vm console.s3.local.vm git.local.vm
192.168.12.11 baku.local.vm
```

## Commands

### Variables

- `VM_NAME` (valid values: `salamandre`, `baku`): The vm name for only create on

### All-in-one (recommended)

The following command create virtual machines, and deploy full stack :

```sh
make test-cluster
```

If you want create only one virtual machine you can specify `VM_NAME` argument (**but** `salamandre` is required for deploy `baku`).

You can exclude some applications by specify environment variable `ANSIBLE_SKIP_TAGS` ([see more informations](#exclude-applications))

If you want change storage pool you can specify the name with `VAGRANT_STORAGE_POOL` environment variable.

### Provisioning virtual machines

Provisioning virtual machines :

```sh
make test-provision
```

If you want create only one virtual machine you can specify `VM_NAME` argument (**but** `salamandre` is required for deploy `baku`).

#### Exclude applications

You can disable some applications by specify environment variable `ANSIBLE_SKIP_TAGS` with one or more next tags.
The apps tags :

- `oidc` (for disable keycloak)
- `gitlab`
- `cloud` (for disable nextcloud and vaultwarden)
- `nextcloud`
- `vaultwarden`

_example_: `ANSIBLE_SKIP_TAGS=oidc,gitlab make test-cluster`, this deploy all cluster but without oidc and gitlab applications

### (Re)Create virtual machines

Create or recreate virtual machines :

```sh
make vagrant
```

If you want (re)create only one VM you can specify `VM_NAME` argument.

### Connect to virtual machine

Use the following command for connect to the machine in SSH :

```sh
make vm-ssh VM_NAME=<name>
```

## Explore

The apps should be available at `https://<app>.local.vm`.

For admin account see [admin credentials](post-installation.md#admin-credentials).

For SSO (OpenID) apps the user is :

- username: `test`
- password `test`

For Vaultwarden admin panel user is :

- username: `admin`
- password: `admin`

### Kubectl access

You can export kubeconfig with following command :

```sh
export KUBECONFIG=./out/kubeconfig/salamandre.dev.yaml;./out/kubeconfig/baku.dev.yaml
```

## Clean up

Delete development environment (credentials, vagrant files, virtual machines, etc) :

```sh
make cleanup
```

## Caveats compare to production environment

- Only accessible on the host machine
- No backup
