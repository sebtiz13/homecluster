# -*- mode: yaml -*-
# vi: set ft=yaml :
ansible_host: 0.0.0.0 # Server IP
ansible_port: 0 # SSH port of server
ansible_user: root # user name used for run ansible (! NEED can run `sudo`)
ansible_sudo_pass: root # password of user for use `sudo`

ssh:
  port: "{{ ansible_port }}"
  users:
    []
    # - name: user
    #   sudoer: true
    #   authorized_key: ""

zfs_pool:
  # The pool type (available values: stripe, mirror, raidz (similar to RAID5) or raidz2 (Similar to RAID5 with dual parity))
  # Default from: group_vars/all.yaml
  type: "{{ zfs_pool_type }}"
  disks:
    []
    # - /dev/by-uuid/5e3051da-d345-4a1c-be59-e987678c005e

# Kubernetes domain
# This is useful when the kubernetes host differ from `root_domain` (`DOMAIN_NAME` env var).
# Eg. `DOMAIN_NAME` is set to `local.vm` but you want salamandre kubernetes at `home2.local.vm`, so add `k3s_domain` with value `home.local.vm` to the `salamandre.yaml` file.
#
# Default: `baku.{{ root_domain }}`
# k3s_domain: ""
