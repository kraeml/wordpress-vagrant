# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # vbguest-plugin installed? https://github.com/dotless-de/vagrant-vbguest
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = true
  end
  config.vm.box = "kraeml/xenial-64-de"
  config.vm.network :private_network, ip: "192.168.68.21"
  config.vm.hostname = "wordpress.rdf.loc"
  # vbguest-hostsupdater installed? https://github.com/cogitatio/vagrant-hostsupdater
  if Vagrant.has_plugin?("vagrant-hostsupdater") then
    config.hostsupdater.aliases = ["alias.testing.de", "alias2.somedomain.com"]
  end
  config.vm.provision :shell, :path => "install.sh"
  #config.vm.synced_folder ".", "/var/www"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    #vb.gui = true

    # Customize the amount of memory,cpu on the VM:
    vb.memory = "1024"
    vb.customize ["modifyvm", :id, "--cpus", 2]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "75"]
    vb.name = "wordpress"
    vb.linked_clone = true if Vagrant::VERSION =~ /^1.8/
  end
end
