environment = "vm"

ssh_host = "192.168.12.10"
ssh_user = "vagrant"
# ssh_use_agent = true
ssh_key = "../../vagrant/id_rsa"

zpool_disks = ["/dev/sda", "/dev/sdb", "/dev/sdc"]

ca_cert = "../../vagrant/.vagrant/ca/rootCA.pem"
ca_key  = "../../vagrant/.vagrant/ca/rootCA-key.pem"

domain           = "local.vm"
manifests_folder = "../../out/manifests/salamandre"
