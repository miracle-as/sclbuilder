#!/usr/bin/env bash


sudo wget -O /etc/yum.repos.d/repos.pip2scl.dk.repo http://repos.pip2scl.dk/repos.pip2scl.dk.repo
sudo yum clean all

sudo yum install -y  miracle-awx-runtime
