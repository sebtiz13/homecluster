# -*- mode: yaml -*-
# vi: set ft=yaml :
ansible_host: 0.0.0.0 # Server IP
ansible_port: 0 # SSH port of server
ansible_user: root # user name used for run ansible (! NEED can run `sudo`)
ansible_sudo_pass: root # password of user for use `sudo`

# Only support one of https://github.com/frankcrawford/it87/blob/master/README (only numbers)
# motherboard_chip: 8686 # Gigabyte_B360M

ssh:
  port: "{{ ansible_port }}"
  users:
    []
    # - name: user
    #   sudoer: true

zfs_pool:
  # The pool type (available values: stripe, mirror, raidz (similar to RAID5) or raidz2 (Similar to RAID5 with dual parity))
  # Default from: group_vars/all.yaml
  type: "{{ zfs_pool_type }}"
  disks:
    []
    # - /dev/by-uuid/5e3051da-d345-4a1c-be59-e987678c005e

smtp_auth:
  host: host
  port: "465"
  username: "contact@{{ root_domain }}"
  password: user

# The user need to be able to :
# - add, edit and delete sub domain
# - add, edit, delete TLS certificate
ovh_credentials:
  application_key: ""
  application_secret: ""
  consumer_key: ""

# The root domains used for each cluster to define sub domains CNAME
root_domains:
  salamandre: "salamandre.{{ root_domain }}"
  baku:"baku.{{ root_domain }}"
