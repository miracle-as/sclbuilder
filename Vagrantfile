# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_worker"
  config.vm.provider "docker" do |d| 
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "awxserver"
  config.vm.provider "docker" do |d|    
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_web_001"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_web_002"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_web_003"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_monitor"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_db"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_rpmbuilder"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_sclbuilder"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

Vagrant.configure("2") do |config|
  config.vm.define "prod_awx"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end

