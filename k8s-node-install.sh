

YUM_VERSION="1.13.0-0.x86_64"
# ipvsadm-1.27-7.el7.x86_64
yum install kubelet-${YUM_VERSION} kubeadm-${YUM_VERSION} kubectl-${YUM_VERSION} ipvsadm -y
systemctl enable kubelet && systemctl start kubelet

K8S_IMAGES_HUB="gcrxio/"
K8S_IMAGES_GCR="k8s.gcr.io/"

# 拉取镜像
cat > /opt/k8s-images-1.13.0.txt <<-EOF
kube-proxy:v1.13.0
pause:3.1
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


# scp k8s-1:/etc/kubernetes/admin.conf /etc/kubernetes/
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" > /etc/bash_profile
source /etc/bash_profile


