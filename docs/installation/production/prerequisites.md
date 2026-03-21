# Production prerequisites

## Hardware requirements

### Initial controller

> The initial controller is the machine used to bootstrap the cluster, we only need it once, you can use your laptop
> or desktop.

- OS: Linux
- Install the following packages:
  - [Mise](https://mise.jdx.dev/)
  - [openSSL](https://www.openssl.org/)
  - [argon2](https://github.com/P-H-C/phc-winner-argon2)
  - [pwgen](https://sourceforge.net/projects/pwgen/)

### Servers

Any modern x86_64 computer(s) should work.

> 🚧 This section is under construction

#### Salamandre

| Component   | Minimum | Recommended |
| ----------- | ------- | ----------- |
| CPU         | -       | -           |
| RAM         | -       | -           |
| Hard drives | -       | -           |

#### Baku

| Component   | Minimum | Recommended |
| ----------- | ------- | ----------- |
| CPU         | -       | -           |
| RAM         | -       | -           |
| Hard drives | -       | -           |

## BIOS setup

> You need to do it once per machine if the default config is not sufficient.

Common settings:

- Use UEFI mode and disable CSM (legacy) mode
- Disable secure boot

## Gather information

- Choose a static IP address for each machine (just the desired address, we don't set anything up yet)
- OS disk name want used for ZFS pool (can be gathered with `ls -la /dev/disk/by-id/ata-*` to use more robust then simple `/dev/sda`)
- SSH root password

## Fill data

1. Duplicate files from `ansible/inventories/prod/host_vars/*.yaml.tpl` and remove the `.tpl` extension
2. Fill the data inside each files
