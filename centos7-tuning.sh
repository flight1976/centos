#!/bin/bash
#
# testing scripts

# Install EPEL repo
# Todo: check epel rpm file. Display warning message if epel rpm not exist.
EPEL_RPM="http://mirror01.idc.hinet.net/epel/7/x86_64/e/epel-release-7-9.noarch.rpm"
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

# Disable NetworkManager and enable network
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service
systemctl restart network

# Disable firewalld and enable iptables-service
systemctl disable firewalld.service
systemctl stop firewalld.service
systemctl enable iptables.service
systemctl start iptables.service
systemctl enable ip6tables.service
systemctl start ip6tables.service


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

#
cat > ~/.screenrc << EOF
termcap xterm 'is=\E[r\E[m\E[2J\E[H\E[?7h\E[?1;4;6l'
terminfo xterm 'is=\E[r\E[m\E[2J\E[H\E[?7h\E[?1;4;6l'
EOF


# Setup shell login timeout 




# Setup out firewall script in /etc/fwrules
# 
mkdir -p /etc/fwrules
cat > /etc/fwrules/iptables << EOF
#!/bin/bash
PATH=/sbin:/usr/sbin:/bin:/usr/local/sbin:/usr/bin
NATOUT="eth0"
OUTIF="eth0"
INIF="eth1"


## RESET ALL RULES ##
iptables -F
iptables -X
iptables -F -t nat
iptables -F -t mangle

## INPUT ##
#block invalid SYN packet
#reference:
#http://www.webhostingtalk.com/showthread.php?t=363499
#http://www.kb.cert.org/vuls/id/464113
#http://phorum.study-area.org/index.php?topic=5195.0
iptables -A INPUT -i \$OUTIF -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -j DROP
iptables -A INPUT -i \$OUTIF -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -i \$OUTIF -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

iptables -A INPUT -i \$OUTIF -p all -s whitelist.example.com/32 -j ACCEPT



#iptables -A INPUT -i \$INIF -p all -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT ! -i lo -m state --state NEW,INVALID -j DROP

## NAT ##
#iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o \$NATOUT -j SNAT --to-source 10.10.10.1
#iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o \$NATOUT -j MASQUERADE

## PREROUTING ##
#iptables -A PREROUTING -t nat -p tcp -d 10.10.10.1/32 --dport 3389 -j DNAT --to 192.168.1.1:3389

## FORWARD ##
iptables -P FORWARD DROP
#iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT

iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m state --state NEW,INVALID -j DROP

# PING flow control
iptables -N ping
iptables -A ping -p icmp --icmp-type echo-request -m limit --limit 20/sec -j ACCEPT
iptables -A ping -p icmp -j DROP
iptables -I INPUT -p icmp --icmp-type echo-request -m state --state NEW -j ping


#

## SAVE CONFIGURATION##
iptables-save > /etc/sysconfig/iptables
EOF
chmod a+x /etc/fwrules/iptables

#create ipv6 ip6tables
cat > /etc/fwrules/v6-ip6tables << EOF
#!/bin/bash
PATH=/sbin:/usr/sbin:/bin:/usr/local/sbin:/usr/bin
NATOUT="em1"
OUTIF="em1"
INIF="em2"
## RESET ALL RULES ##
ip6tables -F
ip6tables -X
ip6tables -F -t mangle

#ipmp v6
ip6tables -A INPUT -i \$OUTIF -p icmpv6 -j ACCEPT

## INPUT ##
#block invalid SYN packet
#reference:
#http://www.webhostingtalk.com/showthread.php?t=363499
#http://www.kb.cert.org/vuls/id/464113
#http://phorum.study-area.org/index.php?topic=5195.0
ip6tables -A INPUT -i \$OUTIF -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -j DROP
ip6tables -A INPUT -i \$OUTIF -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
ip6tables -A INPUT -i \$OUTIF -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

#My home
ip6tables -A INPUT -i \$OUTIF -p all -s 2001:Bxxx:xxxx:1001::/64 -j ACCEPT

#Console
ip6tables -A INPUT -i \$OUTIF -p all -s 2001:bxxx:0:xxxx::227/128 -j ACCEPT

############## Intranet INPUT ##########################
#ip6tables -A INPUT -i \$INIF -p all -j ACCEPT
########################################################

ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT ! -i lo -m state --state NEW,INVALID -j DROP

## FORWARD ##
#ip6tables -P FORWARD DROP
#ip6tables -A FORWARD -s 2001:bxxx:0:xxxx::227/128 -j ACCEPT
ip6tables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -m state --state NEW,INVALID -j DROP

#

## SAVE CONFIGURATION##
ip6tables-save > /etc/sysconfig/ip6tables
EOF
chmod a+x /etc/fwrules/v6-ip6tables

# snmp setting
# todo

# /etc/profile tuning
sed -i "s/HISTSIZE=1000/HISTSIZE=20000\\nTMOUT=7200/" /etc/profile

# log shell command to /var/log/history
# ref: 
# http://webplay.pro/linux/syslog-log-bash-history-every-user.html
# http://stackoverflow.com/questions/3522341/identify-user-in-a-bash-script-called-by-sudo
# https://coderwall.com/p/anphha/save-bash-history-in-syslog-on-centos
cat >> /etc/bashrc << EOF
PROMPT_COMMAND=\$(history -a)
typeset -r PROMPT_COMMAND

function log2syslog
{
   [ \$SUDO_USER ] && user=\$SUDO_USER || user=\`who am i|awk '{print \$1}'\`
   declare command
   command=\$BASH_COMMAND
   logger -p local1.notice -t bash -i -- "\$user=>\$USER[\$$]" : \$PWD : \$command

}
trap log2syslog DEBUG
EOF

# update syslog
cat > /etc/rsyslog.d/history.conf << EOF
# history
local1.notice                                           /var/log/history
EOF

# update logrotate
sed -i '1s/^/\/var\/log\/history\n/' /etc/logrotate.d/syslog


#update package
yum -y update


