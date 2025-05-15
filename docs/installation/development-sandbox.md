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
- [python](https://www.python.org/)
- [jq](https://stedolan.github.io/jq/)
- [yq](https://github.com/mikefarah/yq/)
- [argon2](https://github.com/P-H-C/phc-winner-argon2)
- [pwgen](https://sourceforge.net/projects/pwgen/)

#### Development exclusive

- [libvirt](https://libvirt.org/)
- [virt-install](https://virt-manager.org/)
- [mkcert](https://github.com/FiloSottile/mkcert)

### Configuring DNS

#### With `dnsmasq` (**recommended**)

Create an config file with `dnsmasq` (in `/etc/NetworkManager/dnsmasq.d/<name>.conf` or in `/etc/dnsmasq.conf`) with this following values:

```conf
local=/vm/
address=/.local.vm/192.168.12.10
address=/baku.local.vm/192.168.12.11
address=/metrics.local.vm/192.168.12.11
address=/monitor.local.vm/192.168.12.11
```

> **NOTE**: you can follow this tutorial for setup `dnsmasq` with `NetworkManager` : [Using the NetworkManager’s DNSMasq plugin - fedoramagazine.org](https://fedoramagazine.org/using-the-networkmanagers-dnsmasq-plugin/)

#### With `/etc/hosts`

Add the following line in `/etc/hosts` file:

```conf
192.168.12.10 local.vm vault-secrets.local.vm sso.local.vm git.local.vm
192.168.12.11 baku.local.vm metrics.local.vm monitor.local.vm
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

### Provisioning virtual machines

Provisioning virtual machines :

```sh
make test-provision
```

If you want create only one virtual machine you can specify `VM_NAME` argument (**but** `salamandre` is required for deploy `baku`).

You can precise step with `STEP` argument. This following steps is available :

- `setup`: upgrading operating system and kubernetes
- `k3s_bootstrap`: Deploying applications with flux
- `k3s_configure`: (Re)Configure applications
- `k3s_nuke`: Delete Kubernetes, so it clean all applications

### (Re)Create virtual machines

Create or recreate virtual machines :

```sh
make vm-recreate
```

If you want (re)create only one VM you can specify `VM_NAME` argument.

### Connect to virtual machine

Use the following command for connect to the machine in SSH :

```sh
# Salamandre
ssh ansible@192.168.12.10
# Baku
ssh ansible@192.168.12.11
```

> [!TIP]
> To ignore SSH fingerprint you can add following lines to your `~/.ssh/config` file.
>
> ```txt
> Host 192.168.12.*
>    UserKnownHostsFile /dev/null
>    StrictHostKeyChecking no
> ```

## Explore

The apps should be available at `https://<app>.local.vm`.

For admin account see [admin credentials](post-installation.md#admin-credentials).

For SSO (OpenID) apps the user is :

- username: `test`
- password `Test123!`

> [!NOTE]
> This user only have access to public application as an operator.

### Kubectl access

You can export kubeconfig with following command :

```sh
# Linux/Mac
export KUBECONFIG=./out/kubeconfig/salamandre.dev.yaml:./out/kubeconfig/baku.dev.yaml
# Windows
export KUBECONFIG=./out/kubeconfig/salamandre.dev.yaml;./out/kubeconfig/baku.dev.yaml
```

CF: [The KUBECONFIG environment variable](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#the-kubeconfig-environment-variable)

## Clean up

Delete development environment (credentials, virtual machines, etc) :

```sh
make cleanup
```

## Caveats compare to production environment

- Only accessible on the host machine
- No backup
