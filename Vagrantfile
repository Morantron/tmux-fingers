# -*- mode: ruby -*-
# vi: set ft=ruby :

# requires nfs-utils on host

Vagrant.configure(2) do |config|
  config.vm.box = "freebsd/FreeBSD-11.0-CURRENT"
  config.ssh.shell = "/bin/sh"

  config.vm.network "private_network", ip: "10.0.1.10", mac: "5CA1AB1E0001"
  config.vm.synced_folder ".", "/home/vagrant/shared", :nfs => true

  config.vm.provision "shell", path: './test/bsd_provisioning.sh'
end
