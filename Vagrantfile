# -*- mode: ruby -*-
# vi: set ft=ruby :

# requires nfs-utils on host

Vagrant.configure(2) do |config|
  config.vm.define "ubuntu" do |machine|
    machine.vm.box = "ubuntu/trusty64"
    machine.vm.synced_folder ".", "/home/vagrant/shared"
    machine.vm.provision "shell", path: './test/provisioning/ubuntu.sh'
  end
end
