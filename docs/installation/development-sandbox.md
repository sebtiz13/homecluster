# Development sandbox

The sandbox is intended for trying out the cluster without any hardware or testing changes before applying them to the
production environment.

The local cluster have `local.vm` as base domain but this can be changed by passing `DOMAIN_NAME` environment variable.

For the full list of available commands, see the [commands reference](../references/commands.md).

## Prerequisites

### Host machine

- recommended hardware specifications:
  - CPU: 8 cores
  - RAM: 24 GiB

- OS: Linux

### Install the following packages

- [Mise](https://mise.jdx.dev/)
- [openSSL](https://www.openssl.org/)
- [argon2](https://github.com/P-H-C/phc-winner-argon2)
- [pwgen](https://sourceforge.net/projects/pwgen/)

#### Development exclusive

- [libvirt](https://libvirt.org/)

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
192.168.12.10 local.vm secrets.local.vm sso.local.vm git.local.vm
192.168.12.11 baku.local.vm metrics.local.vm monitor.local.vm
```

## Quick start

Create VMs and deploy the full stack:

```sh
mise run cluster:deploy dev
```

### Virtual machines

Each command accepts an optional `--host <hostname>` flag to target a single node.

| Commands              | Description            |
| --------------------- | ---------------------- |
| `mise run vm:create`  | Create one or all VMs  |
| `mise run vm:destroy` | Destroy one or all VMs |
| `mise run vm:start`   | Start one or all VMs   |
| `mise run vm:stop`    | Stop one or all VMs    |

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
export KUBECONFIG=./out/kubeconfig/dev.yaml
```

## Clean up

Delete development environment (credentials, virtual machines, etc) :

```sh
mise run cleanup
```

## Caveats compare to production environment

- Only accessible on the host machine
- No backup
