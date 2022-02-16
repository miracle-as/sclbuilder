Vagrant.configure("2") do |config|
  config.vm.define "prod_sclbuilder_database" do | database |
    database.vm.synced_folder "/opt/awxrpm/data/pgsql", "/var/lib/pgsql", docker_consistency: "delegated"
    database.vm.network "forwarded_port", guest: 5432, host: 5432
    database.vm.provider "docker" do |d|
      d.build_dir = "docker/postgres/."
      d.env = {
        "POSTGRESQL_ADMIN_PASSWORD":"sclbuilder"
      }
    end
  end

  config.vm.define "prod_sclbuilder_worker" do | worker |
    worker.vm.synced_folder "/opt/awxrpm/data/repo", "/repo", docker_consistency: "delegated" 
    worker.vm.provider "docker" do |d|
      d.build_dir = "docker/rhel/."
#      d.create_args = ["--user=1000","--userns=keep-id"]
    end
  end

  config.vm.define "prod_sclbuilder_rpmbuilder" do | rpmbuilder |
    rpmbuilder.vm.provider "docker" do |d|
      d.build_dir = "docker/rhel/."
    end
  end

  config.vm.define "prod_sclbuilder_sclbuilder" do | sclbuilder |
    sclbuilder.vm.provider "docker" do |d|
      d.build_dir = "docker/rhel/."
    end
  end

  config.vm.define "prod_sclbuilder_database_ui" do | database_ui |
    database_ui.vm.provider "docker" do |d|
      d.build_dir = "docker/rhel/."
    end
  end

end
