environment = "vm"

ssh_host = "192.168.12.10"
ssh_user = "vagrant"
# ssh_use_agent = true
ssh_key = "../vagrant/id_rsa" # `../vagrant` is required because the cwd is in `../terraform`

zpool_disks = ["/dev/sda", "/dev/sdb", "/dev/sdc"]
