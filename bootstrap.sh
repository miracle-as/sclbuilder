sudo dnf -y install yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf -y install rsync gcc zlib-devel libvirt-devel cmake ruby ruby-devel vagrant podman podman-docker

#vl down
#vl up
#vl ansible_inventory > inventory 
#vl ssh_config  > ~/.ssh/config
#vl ssh_config  > /tmp/pip2scl.ssh.config
rm -r  ~/.ansible
ansible-galaxy install -f -r roles/requirements.yml
ansible-playbook -i container-dynamic buildawx.playbook.yml 
ssh prod_sclbuilder_worker sudo mkdir /home/vagrant
scp /home/jho/.ssh/scldistro root@prod_sclbuilder_worker:/home/vagrant/
ansible-galaxy install -f -r roles/requirements.yml
ansible-playbook -i inventory buildawx.playbook.yml 

