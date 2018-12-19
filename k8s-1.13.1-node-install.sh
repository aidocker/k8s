

YUM_VERSION="1.13.1-0.x86_64"
# ipvsadm-1.27-7.el7.x86_64
yum install kubelet-${YUM_VERSION} kubeadm-${YUM_VERSION} kubectl-${YUM_VERSION} ipvsadm -y
systemctl enable kubelet && systemctl start kubelet

docker load < /opt/k8s/kube-apiserver:v1.13.1.tar
docker load < /opt/k8s/kube-controller-manager:v1.13.1.tar
docker load < /opt/k8s/kube-scheduler:v1.13.1.tar
docker load < /opt/k8s/kube-proxy:v1.13.1.tar
docker load < /opt/k8s/pause:3.1.tar
docker load < /opt/k8s/etcd:3.2.24.tar
docker load < /opt/k8s/coredns:1.2.6.tar

# scp k8s-1:/etc/kubernetes/admin.conf /etc/kubernetes/
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" > /etc/bash_profile
source /etc/bash_profile



docker images |awk 'BEGIN { OFS=":"} {print $1,$2}'
docker images|awk 'NR == 1 {next} BEGIN { OFS=":"} {print $1,$2}'
