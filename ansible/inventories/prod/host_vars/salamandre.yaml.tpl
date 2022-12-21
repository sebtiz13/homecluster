# -*- mode: yaml -*-
# vi: set ft=yaml :
ansible_host: 0.0.0.0
ansible_port: 0
ansible_user: root
host_prefix: "192.168.1.10/24" # CIDR format with this schema: address/netmask

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

basic_auth_users:
  # - name: user
  #   password: password

smtp_auth:
  host: host
  port: "465"
  username: "contact@{{ root_domain }}"
  password: user

cert_manager_ovh_auth:
  application_key: ""
  application_secret: ""
  consumer_key: ""
