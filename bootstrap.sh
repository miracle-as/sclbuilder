sudo dnf -y install yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf -y install rsync gcc zlib-devel libvirt-devel cmake ruby ruby-devel vagrant podman podman-docker redis
sudo sed -i 's/bind 127.0.0.1//g' /etc/redis/redis.conf
sudo sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf
sudo systemctl enable redis
sudo systemctl restart redis

mkdir -p /opt/awxrpm/data/pgsql
chown -R 26:26 /opt/awxrpm/data/pgsql
vagrant up --provider=docker

rm -r  ~/.ansible
ansible-galaxy install -f -r roles/requirements.yml
ansible-galaxy collection install community.postgresql
ansible-galaxy install containers.podman # Internal podman connection plugin is broken
ansible-playbook -i container-dynamic build_enviroment_100_db.yml

 
