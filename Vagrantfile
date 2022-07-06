# -*- mode: ruby -*-
# vi: set ft=ruby :

# requires nfs-utils on host

Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
  end

  config.vm.define "ubuntu" do |machine|
    machine.vm.box = "ubuntu/focal64"
    machine.vm.synced_folder ".", "/home/vagrant/shared"
    machine.vm.provision "shell", path: "./spec/provisioning/ubuntu.sh"
  end
end
