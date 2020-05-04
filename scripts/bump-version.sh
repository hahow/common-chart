#!/usr/bin/env bash

set -eu

printusage() {
  echo "Usage: bump-version.sh [patch|minor|major]"
}

ROOT_PATH=$(dirname "$0")/..

if [[ $# -eq 0 ]]
then
  printusage
  exit 1
fi

UPDATED_PART=$1
if [[ ! ($UPDATED_PART == "patch" || $UPDATED_PART == "minor" || $UPDATED_PART == "major") ]]
then
  printusage
  exit 1
fi

CURRENT_VERSION=$(sed -ne 's/^version: \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$/\1/p' $ROOT_PATH/Chart.yaml)
MAJOR_VERSION=$(echo $CURRENT_VERSION | cut -d '.' -f 1)
MINOR_VERSION=$(echo $CURRENT_VERSION | cut -d '.' -f 2)
PATCH_VERSION=$(echo $CURRENT_VERSION | cut -d '.' -f 3)

if [[ $UPDATED_PART = 'patch' ]]
then
  (( PATCH_VERSION++ ))
elif [[ $UPDATED_PART = 'minor' ]]
then
  (( MINOR_VERSION++ ))
  PATCH_VERSION=0
elif [[ $UPDATED_PART = 'major' ]]
then
  (( MAJOR_VERSION ++ ))
  MINOR_VERSION=0
  PATCH_VERSION=0
fi

NEW_VERSION=$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION
echo "Bumping Version $CURRENT_VERSION => $NEW_VERSION..."

case $(sed --help 2>&1) in
  *GNU*)
    SED=(sed -i)
    ;;

  *)
    SED=(sed -i "")
    ;;
esac

echo "Updating starter/Chart.yaml..."
"${SED[@]}" "s/^  version: \"$CURRENT_VERSION\"$/  version: \"$NEW_VERSION\"/" $ROOT_PATH/starter/Chart.yaml

echo "Updating README.md..."
"${SED[@]}" "/^### Adding Dependency$/,/^### Using Starter$/s;version: $CURRENT_VERSION;version: $NEW_VERSION;" $ROOT_PATH/README.md

echo "Updating Chart.yaml..."
"${SED[@]}" "s/^version: $CURRENT_VERSION$/version: $NEW_VERSION/" $ROOT_PATH/Chart.yaml
