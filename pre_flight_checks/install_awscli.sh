#!/usr/bin/env bash

FILE="awscli-bundle.zip"

download() {
  wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
}

if [ ! -f ${FILE} ]; then
  download
fi

if [ ! -d awscli-bundle ]; then
  unzip awscli-bundle.zip
fi

./awscli-bundle/install -b ~/bin/aws

rm -rf awscli-bundle*