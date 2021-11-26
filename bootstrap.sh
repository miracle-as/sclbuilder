vl down
vl up
vl ansible_inventory > inventory 
vl ssh_config  > ~/.ssh/config
vl ssh_config  > /tmp/pip2scl.ssh.config
rm -r  ~/.ansible
ansible-galaxy install -f -r roles/requirements.yml
ansible-playbook -i inventory buildawx.playbook.yml 
ssh sclbuilder sudo mkdir /home/vagrant
scp /home/jho/.ssh/scldistro root@sclbuilder:/home/vagrant/
ansible-galaxy install -f -r roles/requirements.yml
ansible-playbook -i inventory buildawx.playbook.yml 

