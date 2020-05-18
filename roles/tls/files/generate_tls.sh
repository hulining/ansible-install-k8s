#!/bin/bash

day=$1
cd /etc/kubernetes/pki

########### CA 证书 ##########
# kubernetes-ca:kubernetes CA 证书
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -config openssl.cnf -subj "/CN=kubernetes-ca" -extensions v3_ca -out ca.crt -days ${day}

# etcd-ca etcd CA 证书
openssl genrsa -out etcd/ca.key 2048
openssl req -x509 -new -nodes -key etcd/ca.key -config openssl.cnf -subj "/CN=etcd-ca" -extensions v3_ca -out etcd/ca.crt -days ${day}

# front-proxy-ca kubernetes 高可用 CA 证书
openssl genrsa -out front-proxy-ca.key 2048
openssl req -x509 -new -nodes -key front-proxy-ca.key -config openssl.cnf -subj "/CN=kubernetes-ca" -extensions v3_ca -out front-proxy-ca.crt -days ${day}
########### CA 证书 ##########

########### 使用 CA 证书进行签署 ##########
# apiserver-etcd-client: apiserver 向 etcd 发送请求时使用证书,需要使用 etcd-ca 进行签署
openssl genrsa -out apiserver-etcd-client.key 2048
openssl req -new -key apiserver-etcd-client.key -subj "/CN=apiserver-etcd-client/O=system:masters" -out apiserver-etcd-client.csr
openssl x509 -in apiserver-etcd-client.csr -req -CA etcd/ca.crt -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd -extfile openssl.cnf -out apiserver-etcd-client.crt -days ${day}

# kube-etcd: etcd 自身的服务端证书,需要使用 etcd-ca 进行签署
openssl genrsa -out etcd/server.key 2048
openssl req -new -key etcd/server.key -subj "/CN=etcd-server" -out etcd/server.csr
openssl x509 -in etcd/server.csr -req -CA etcd/ca.crt -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd -extfile openssl.cnf -out etcd/server.crt -days ${day}

# kube-etcd-peer: etcd 集群内部交互时使用的证书,需要使用 etcd-ca 进行签署
openssl genrsa -out etcd/peer.key 2048
openssl req -new -key etcd/peer.key -subj "/CN=etcd-peer" -out etcd/peer.csr
openssl x509 -in etcd/peer.csr -req -CA etcd/ca.crt -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd -extfile openssl.cnf -out etcd/peer.crt -days ${day}

# kube-etcd-healthcheck-client: 客户端向 etcd 发送请求时使用的证书,需要使用 etcd-ca 进行签署
openssl genrsa -out etcd/healthcheck-client.key 2048
openssl req -new -key etcd/healthcheck-client.key -subj "/CN=etcd-client" -out etcd/healthcheck-client.csr
openssl x509 -in etcd/healthcheck-client.csr -req -CA etcd/ca.crt -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd -extfile openssl.cnf -out etcd/healthcheck-client.crt -days ${day}

# kube-apiserver: apiserver 服务端证书,需要使用 kubernetes-ca 进行签署
openssl genrsa -out apiserver.key 2048
openssl req -new -key apiserver.key -subj "/CN=kube-apiserver" -config openssl.cnf -out apiserver.csr
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days ${day} -extensions v3_req_apiserver -extfile openssl.cnf -out apiserver.crt

# apiserver-kubelet-client: kubelet 向 apiserver 发送请求时使用证书,需要使用 kubernetes-ca 进行签署
openssl genrsa -out  apiserver-kubelet-client.key 2048
openssl req -new -key apiserver-kubelet-client.key -subj "/CN=apiserver-kubelet-client/O=system:masters" -out apiserver-kubelet-client.csr
openssl x509 -req -in apiserver-kubelet-client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days ${day} -extensions v3_req_client -extfile openssl.cnf -out apiserver-kubelet-client.crt

# front-proxy-client: 客户端向高可用 apiserver 发送请求时使用的证书,需要使用 front-proxy-ca 进行签署
openssl genrsa -out  front-proxy-client.key 2048
openssl req -new -key front-proxy-client.key -subj "/CN=front-proxy-client" -out front-proxy-client.csr
openssl x509 -req -in front-proxy-client.csr -CA front-proxy-ca.crt -CAkey front-proxy-ca.key -CAcreateserial -days ${day} -extensions v3_req_client -extfile openssl.cnf -out front-proxy-client.crt

# kube-scheduler: scheduler.kubeconfig 中指定 scheduler 组件向 apiserver 发送请求时证书
openssl genrsa -out  kube-scheduler.key 2048
openssl req -new -key kube-scheduler.key -subj "/CN=system:kube-scheduler" -out kube-scheduler.csr
openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days ${day} -extensions v3_req_client -extfile openssl.cnf -out kube-scheduler.crt

# sa.pub sa.key: controller-manager.kubeconfig 中指定 controller-manager 组件向 apiserver 发送请求时证书
openssl genrsa -out  sa.key 2048
openssl ecparam -name secp521r1 -genkey -noout -out sa.key
openssl ec -in sa.key -outform PEM -pubout -out sa.pub
openssl req -new -sha256 -key sa.key -subj "/CN=system:kube-controller-manager" -out sa.csr
openssl x509 -req -in sa.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days ${day} -extensions v3_req_client -extfile openssl.cnf -out sa.crt

# admin: admin.kubeconfig 中指定 kubectl 向 apiserver 发送请求时证书
openssl genrsa -out  admin.key 2048
openssl req -new -key admin.key -subj "/CN=kubernetes-admin/O=system:masters" -out admin.csr
openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days ${day} -extensions v3_req_client -extfile openssl.cnf -out admin.crt

# 删除所有 csr 和 srl
find . -name "*.csr" -o -name "*.srl" | xargs  rm -f
