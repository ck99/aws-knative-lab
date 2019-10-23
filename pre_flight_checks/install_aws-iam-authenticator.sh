#!/usr/bin/env bash

OS="linux_amd64"
VERSION="0.4.0"

FILE="aws-iam-authenticator_${VERSION}_${OS}"

download() {
  OS=$1
  VERSION=$2

  wget https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${VERSION}/aws-iam-authenticator_${VERSION}_${OS}
}

if [ ! -f ${FILE} ]; then
  download  ${OS} ${VERSION}
fi
