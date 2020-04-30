#!/usr/bin/env bash

set -eu

if [[ $# -eq 0 ]]
then
  echo "Usage: create-chart.sh <chartname>"
  exit 1
fi

CHART_NAME=$1

echo "Creating chart..."
mkdir "$CHART_NAME"
curl --proto '=https' --tlsv1.2 -sSf https://codeload.github.com/hahow/common-chart/tar.gz/master | \
  tar -xz -C "$CHART_NAME" --strip=2 common-chart-master/starter
find "$CHART_NAME" -type f | xargs sed -i "" "s/<CHARTNAME>/$CHART_NAME/g"

echo "Building dependencies..."
helm dep build "$CHART_NAME"
