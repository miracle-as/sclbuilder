# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/rhel8"
  config.vm.define "prod_sclbuilder_worker"
  config.vm.provider "virtualbox" do |v|
    v.memory = 8192
    v.cpus = 8
  end

  if Vagrant.has_plugin?('vagrant-registration')
    config.registration.org = '14498519'
    config.registration.activationkey = 'virt-lightening'
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "generic/rhel8"
  config.vm.define "awxserver"
  config.vm.provider "virtualbox" do |v|
    v.memory = 8192
    v.cpus = 8
  end

  if Vagrant.has_plugin?('vagrant-registration')
    config.registration.org = '14498519'
    config.registration.activationkey = 'virt-lightening'
  end
end

