#!/bin/bash

export PATH=/usr/local/bin:$PATH

[ -z "$1" ] && KUBE_APISERVER=`kubectl config view --output=jsonpath='{.clusters[].cluster.server}'` || KUBE_APISERVER=$1

kubectl -n kube-system get sa kube-proxy ||  kubectl -n kube-system create serviceaccount kube-proxy

kubectl get clusterrolebinding kubeadm:kube-proxy || kubectl create clusterrolebinding kubeadm:kube-proxy --clusterrole system:node-proxier --serviceaccount kube-system:kube-proxy

set -e

CLUSTER_NAME=`kubectl config view -o jsonpath='{.clusters[0].name}'`

KUBE_CONFIG="kube-proxy.kubeconfig"

while [ -z "$SECRET" ];do
 SECRET=$(kubectl -n kube-system get sa/kube-proxy --output=jsonpath='{.secrets[0].name}')
  sleep 1
done

JWT_TOKEN=$(kubectl -n kube-system get secret/$SECRET --output=jsonpath='{.data.token}' | base64 -d)

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=/etc/kubernetes/${KUBE_CONFIG}

kubectl config set-context ${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=${CLUSTER_NAME} \
  --kubeconfig=/etc/kubernetes/${KUBE_CONFIG}

kubectl config set-credentials ${CLUSTER_NAME} --token=${JWT_TOKEN} --kubeconfig=/etc/kubernetes/${KUBE_CONFIG}

kubectl config use-context ${CLUSTER_NAME} --kubeconfig=/etc/kubernetes/${KUBE_CONFIG}

kubectl config view --kubeconfig=/etc/kubernetes/${KUBE_CONFIG}

chmod +r /etc/kubernetes/${KUBE_CONFIG}
