# -*- mode: ruby -*-
# vi: set ft=ruby :

# requires nfs-utils on host

Vagrant.configure(2) do |config|
  config.vm.define "bsd" do |machine|
    machine.vm.box = "freebsd/FreeBSD-10.3-RELEASE"
    machine.ssh.shell = "/bin/sh"

    machine.vm.base_mac = "080027D14C66"
    machine.vm.network "private_network", ip: "10.0.1.10", mac: "5CA1AB1E0001"
    machine.vm.synced_folder ".", "/home/vagrant/shared", nfs: true, nfs_udp: false

    machine.vm.provision "shell", path: './test/provisioning/bsd.sh'
  end

  config.vm.define "ubuntu" do |machine|
    machine.vm.box = "ubuntu/trusty64"
    machine.vm.synced_folder ".", "/home/vagrant/shared"
    machine.vm.provision "shell", path: './test/provisioning/ubuntu.sh'
  end
end
