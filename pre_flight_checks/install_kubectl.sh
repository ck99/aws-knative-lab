#!/usr/bin/env bash

OS="linux/amd64"

FILE="kubectl"


install_kubectl() {
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin
}


download() {
  OS=$1
  VERSION=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`

  wget https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/${OS}/kubectl
  chmod +x kubectl
}

if [ ! -f ${FILE} ]; then
  download  ${OS}
fi
