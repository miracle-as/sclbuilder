# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_worker"
  config.vm.provider "docker" do |d| 
    d.build_dir = "docker/rhel/."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_rpmbuilder"
  config.vm.provider "docker" do |d|
    d.build_dir = "docker/rhel/."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_sclbuilder"
  config.vm.provider "docker" do |d|
    d.build_dir = "docker/rhel/."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_database"
  config.vm.provider "docker" do |d|
    d.build_dir = "docker/postgres/."
  end
end

