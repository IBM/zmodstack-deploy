#!/bin/bash

SRC_ROOT=`git rev-parse --show-toplevel`
VERSION="1.1.0"

echo "Beginning azure build for version: ${VERSION}"

cd $SRC_ROOT/azure/marketplace

echo "Running arm-ttk validation"
docker run -it --rm -v $PWD:/template hawaku/arm-ttk ./Test-AzTemplate.sh -TemplatePath /template

echo "Creating .zip file for Azure Marketplace"
mkdir -p $SRC_ROOT/.local/azure/builds
zip $SRC_ROOT/.local/azure/builds/zmodstack-byol-$VERSION.zip mainTemplate.json createUiDefinition.json

echo "Build successful: $SRC_ROOT/.local/azure/builds/zmodstack-byol-$VERSION.zip"