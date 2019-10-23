#!/usr/bin/env bash

OS="linux_amd64"
VERSION="0.12.12"

FILE="terraform_${VERSION}_${OS}.zip"

download() {
  OS=$1
  VERSION=$2

  wget https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_${OS}.zip
}

if [ ! -f ${FILE} ]; then
  download  ${OS} ${VERSION}
fi

if [ ! -f terraform ]; then
  unzip ${FILE}
fi
