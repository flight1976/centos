#!/bin/bash
#
# testing scripts

# Install EPEL repo
# Todo: check epel rpm file. Display warning message if epel rpm not exist.
EPEL_RPM="http://mirror01.idc.hinet.net/epel/7/x86_64/e/epel-release-7-5.noarch.rpm"
rpm -ivh $EPEL_RPM


# Change yum repo to Taiwan mirror site (http://mirror01.idc.hinet.net/centos)
# backup config 
mkdir -p /root/.linux-tunning-bak
tar zcvf /root/.linux-tunning-bak/etc-yum.repo.d-bak.tgz /etc/yum.repos.d
# Use find + sed searching and replacing string
find /etc/yum.repos.d -type f -name CentOS-Base.repo -exec sed -i 's/#baseurl=http:\/\/mirror.centos.org/baseurl=http:\/\/mirror01.idc.hinet.net/' {} \;
find /etc/yum.repos.d -type f -name CentOS-Base.repo -exec sed -i 's/^mirrorlist/#mirrorlist/' {} \;
find /etc/yum.repos.d -type f -name epel.repo -exec sed -i 's/#baseurl=http:\/\/download.fedoraproject.org\/pub/baseurl=http:\/\/mirror01.idc.hinet.net/' {} \;
find /etc/yum.repos.d -type f -name epel.repo -exec sed -i 's/^mirrorlist/#mirrorlist/' {} \;

# Install some daily use packages.
yum -y install net-tools wget w3m curl telnet lftp tcpdump vim iptables-services

# root user .bashrc customize

# disable NetworkManager and enable network
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service

systemctl restart network


# Customize vim env
cat > /root/.vimrc << EOF
set background=dark

EOF

# Customize bash env
cat > /root/.bashrc << EOF
# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

PS1='[\[\033[34;1m\]\u\[\033[39;0m\]@\[\033[31;2m\]\H \[\033[34;1m\]\w\[\033[39;0m\]]# '

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

EOF

