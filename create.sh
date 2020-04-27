#!/usr/bin/env bash

set -exu

if [[ $# -eq 0 ]]
then
    echo "No argument supplied"
    exit 1
fi

mkdir "$1"
curl --proto '=https' --tlsv1.2 -sSf https://codeload.github.com/hahow/common-chart/tar.gz/master | \
  tar -xz -C "$1" --strip=2 common-chart-master/starter
find "$1" -type f | xargs sed -i "" "s/<CHARTNAME>/$1/g"

helm dep build "$1"
