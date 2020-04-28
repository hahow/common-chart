#!/usr/bin/env bash

set -eu

printusage() {
  echo "Usage: bump-version.sh [patch|minor|major]"
}

ROOT_PATH=$(dirname "$0")/..

if [[ $# -eq 0 ]]; then
  printusage
  exit 1
fi

UPDATED_PART=$1
if [[ ! ($UPDATED_PART == "patch" || $UPDATED_PART == "minor" || $UPDATED_PART == "major") ]]; then
  printusage
  exit 1
fi

CURRENT_VERSION=$(sed -ne 's/^version: \([0-9]\+\.[0-9]\+\.[0-9]\+\)$/\1/p' $ROOT_PATH/Chart.yaml)
MAJOR_VERSION=$(echo $CURRENT_VERSION | cut -d '.' -f 1)
MINOR_VERSION=$(echo $CURRENT_VERSION | cut -d '.' -f 2)
PATCH_VERSION=$(echo $CURRENT_VERSION | cut -d '.' -f 3)

UPDATED_PART_VAR=$(echo $UPDATED_PART | tr '[:lower:]' '[:upper:]')_VERSION
eval $UPDATED_PART_VAR'=$(($'$UPDATED_PART_VAR' + 1))'
NEW_VERSION=$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION

echo "Bumping Version $CURRENT_VERSION => $NEW_VERSION..."

echo "Updating starter/Chart.yaml..."
sed -i"" "s/^  version: \"$CURRENT_VERSION\"$/  version: \"$NEW_VERSION\"/" $ROOT_PATH/starter/Chart.yaml

echo "Updating README.md..."
sed -i"" "/^### Adding Dependency$/,/^### Using Starter$/s;version: $CURRENT_VERSION;version: $NEW_VERSION;" $ROOT_PATH/README.md

echo "Updating Chart.yaml..."
sed -i"" "s/^version: $CURRENT_VERSION$/version: $NEW_VERSION/" $ROOT_PATH/Chart.yaml
