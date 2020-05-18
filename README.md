
# ansible install kubernetes

## 说明

- kube-proxy 采用 ds 方式部署
- 网络插件采用 flannel, 并以 ds 方式部署

## 使用

1. 修改 `group_vars/all.yml` 中默认配置变更为自己需要的配置
2. 下载 `group_vars/all.yml` 中 `KUBE_VERSION` 变量指定版本的二进制文件,保存到指定位置

> `/usr/local/bin/` 下二进制文件

- `kube-apiserver`
- `kube-controller-manager`
- `kube-scheduler`
- `kubelet`
- `kubectl`
- `etcd`
- `etcdctl`

> `/opt/packages/` 下 cni-plugins 网络插件包

- `cni-plugins-amd64-<version>.tgz`
