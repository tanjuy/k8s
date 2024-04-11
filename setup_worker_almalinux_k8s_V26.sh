#!/usr/bin/env bash

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Reset
Color_Off='\033[0m'       # Text Reset


echo -e "$BGreen --> System swap is being closed... <--$Color_Off \n"
sleep 7
# 
sudo swapon --show
#
sudo swapoff -av
# swap'ı kalıcı olarak kapatıyoruz:
sudo sed -i ‘/swap/s/^/#/’ /etc/fstab

echo -e  "$BWhite --> SELinux is being configured <--$Color_Off \n"
# Set SELinux in permissive mode (effectively disabling it):
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


echo -e "-->$BPurple Kernel Module is being appended  <--$Color_Off \n"
sleep 7
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


# sysctl params required by setup, params persist across reboots:
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot:
sudo sysctl --system


echo -e "\n $BGreen -->  Docker Installation Process <-- $Color_Off\n"
sleep 7
sudo yum install -y yum-utils

sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker



echo -e "\n $BGreen Kubernetes Installation Process $Color_Off\n"
sleep 7
# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo:
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.26/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.26/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install systemd-resolved.x86_64


sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd.service
