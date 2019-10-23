#!/usr/bin/env bash

OS="linux-amd64"
VERSION="v2.14.3"

FILE="helm-${VERSION}-${OS}.tar.gz"

download() {
  OS=$1
  VERSION=$2

  wget https://get.helm.sh/helm-${VERSION}-${OS}.tar.gz
}

if [ ! -f ${FILE} ]; then
  download  ${OS} ${VERSION}
fi

if [ ! -f ${OS}/helm ]; then
  tar xvzf ${FILE}
fi
