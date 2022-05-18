#!/usr/bin/env bash

echo -n "docker is "; systemctl is-active docker; \
echo -n "kubelet is "; systemctl is-active kubelet; \
echo -n "kube-proxy is "; systemctl is-active kube-proxy
exit
