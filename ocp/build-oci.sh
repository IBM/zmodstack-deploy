#!/bin/bash

# Name used for local manifest during creation process
MANIFEST_NAME="tekton-ansible"

# Image registry where manifest will be pushed
REGISTRY="icr.io"
NAMESPACE="zmodstack/deploy"
REPO="tekton-ansible"
TAG="latest"
IMAGE=$REGISTRY/$NAMESPACE/$REPO:$TAG

# local (single-architecture) build
# podman build --tag $MANIFEST_NAME .

# # Build and push arm64, amd64, s390x
podman manifest rm $MANIFEST_NAME
podman build --jobs 3 --platform linux/arm64/v8,linux/amd64,linux/s390x --manifest $MANIFEST_NAME .
podman manifest push $MANIFEST_NAME docker://$IMAGE