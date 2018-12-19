# 环境介绍
# k8s-1 192.168.1.231 master
# k8s-2 192.168.1.232 node
# k8s-3 192.168.1.233 node
# k8s-4 192.168.1.234 node
# k8s-5 192.168.1.235 node

cat > /opt/node.txt <<-EOF
k8s-2
k8s-3
k8s-4
k8s-5
EOF


YUM_VERSION="1.13.0-0.x86_64"
# ipvsadm-1.27-7.el7.x86_64
yum install kubelet-${YUM_VERSION} kubeadm-${YUM_VERSION} kubectl-${YUM_VERSION} ipvsadm -y
systemctl enable kubelet && systemctl start kubelet

K8S_IMAGES_HUB="gcrxio/"
K8S_IMAGES_GCR="k8s.gcr.io/"

# 拉取镜像
cat > /opt/k8s-images-1.13.0.txt <<-EOF
kube-apiserver:v1.13.0
kube-controller-manager:v1.13.0
kube-scheduler:v1.13.0
kube-proxy:v1.13.0
etcd:3.2.24
pause:3.1
coredns:1.2.6
EOF


cat /opt/k8s-images-1.13.0.txt | while read line
do
  IMAGES_NUM=`docker images  ${K8S_IMAGES_GCR}${line} |wc -l`
  if [[ $IMAGES_NUM -ne 2 ]]; then
    docker pull ${K8S_IMAGES_HUB}${line}
    # if [[ $? -ne 0 ]]; then
    #   echo "docker pull ${K8S_IMAGES_HUB}${line} failure" > /opt/k8s_install.log
    # fi
  fi
done
# 打tag
docker images | sed 's#gcrxio/#k8s.gcr.io/#' | awk '{print "docker tag "$3" "$1":"$2}' | tail -7| sh

# 删除旧镜像
if [[ $? -eq 0 ]]; then
  cat /opt/k8s-images-1.13.0.txt | while read line
  do
    IMAGES_NUM=`docker images  ${K8S_IMAGES_HUB}${line} |wc -l`
    if [[ $IMAGES_NUM -eq 2 ]]; then
          docker rmi ${K8S_IMAGES_HUB}${line}
    fi
  done
fi

# docker pull quay.io/coreos/flannel:v0.10.0-amd64

# 将机器上的所有镜像打包到haha.tar文件里面。
# docker save $(docker images | grep -v REPOSITORY | awk 'BEGIN{OFS=":";ORS=" "}{print $1,$2}') -o k8s.tar
# 加载镜像：

# docker load -i k8s.tar

kubeadm init \
   --kubernetes-version=v1.13.0 \
   --pod-network-cidr=10.244.0.0/16 \
   --apiserver-advertise-address=192.168.1.233 > /opt/k8s-install.log

# export KUBECONFIG=/etc/kubernetes/admin.conf

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/bash_profile
# echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/bashrc
source /etc/bash_profile
# source /etc/bashrc
tail -2 /opt/k8s-install.log |head -1 |sed 's/^ *\| *$//g' >> /opt/k8s-node-install.sh
#安装网络插件
# wget https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
# 在官方的基础上加入了容忍not-ready
# - key: node.kubernetes.io/not-ready
#   operator: Exists
#   effect: NoSchedule
cd /opt
wget https://raw.githubusercontent.com/aidocker/k8s/master/kube-flannel.yml
kubectl apply -f kube-flannel.yml


#并发执行脚本
cat /opt/node.txt | while read line
do
{
scp /etc/kubernetes/admin.conf ${line}:/etc/kubernetes/
scp /opt/k8s-node-install.sh ${line}:/opt/ |chmod +x /opt/k8s-node-install.sh
ssh ${line} <<-EOF
/opt/k8s-node-install.sh >> /opt/k8s-node-install.log
exit
EOF
}&
wait
done

kubectl get no

