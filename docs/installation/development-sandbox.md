# Development sandbox

The sandbox is intended for trying out the cluster without any hardware or testing changes before applying them to the
production environment.

The local cluster have `local.vm` as base domain.

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
- [Terraform](https://www.terraform.io/)
- [Helm](https://helm.sh/)

### Configuring DNS

#### With `dnsmasq` (**recommended**)

Create an config file with `dnsmasq` (in `/etc/NetworkManager/dnsmasq.d/<name>.conf` or in `/etc/dnsmasq.conf`) with this following values:

```conf
listen-address=127.0.0.1 # required only if no 'dnsmasq' config is already done
address=/baku.local.vm/192.168.12.11
address=/local.vm/192.168.12.10
```

#### With `/etc/hosts`

Add the following line in `/etc/hosts` file:

```conf
192.168.12.10 local.vm argocd.local.vm vault-secrets.local.vm sso.local.vm s3.local.vm console.s3.local.vm git.local.vm
```

## Commands

### Variables

- `VM_NAME` (valid values: `salamandre.vm`, `baku.vm`): The vm name for only create on

### All-in-one (recommended)

The following command create virtual machine, and deploy all stack :

```sh
make test-cluster VM_NAME=<name>
```

### (Re)Create virtual machines

Create or recreate VMs :

```sh
make vagrant
```

If you want create only one VM you can specify `VM_NAME` argument.

### (Re)Create virtual machine with minimal configuration

Create or recreate VM with `k3s`, and `zfs`, and `postgresql` pre installed :

```sh
make vm-init-state VM_NAME=<name>
```

### Reset virtual machine to minimal configuration

You can reset machine to [minimal configuration](#recreate-virtual-machine-with-minimal-configuration) for clean
machines with following command :

```sh
make vm-reset-state VM_NAME=<name>
```

### Connect to virtual machine

Use the following command for connect to the machine in SSH :

```sh
make vm-ssh VM_NAME=<name>
```

## GitLab Agent

For deploy GitLab Agent please follow [this section](../gitlab-agent.md).

## Explore

The apps should be available at `https://<app>.local.vm`.

See [admin credentials] for default passwords.

For SSO (OpenID) apps the user is :

- username: `test`
- password `test`

## Clean up

Delete terraform cache and virtual machines :

```sh
make cleanup
```

## Caveats compare to production environment

- Only accessible on the host machine
- No backup
