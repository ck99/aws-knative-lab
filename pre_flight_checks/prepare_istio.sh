#!/usr/bin/env bash

export ISTIO_VERSION=1.2.7

download() {
  curl -L https://git.io/getLatestIstio | sh -
}

if [ ! -d istio-${ISTIO_VERSION} ]; then
  download
fi
