#!/bin/bash

# this script applies the add ons kustomization to the cluster.
#
# to be clear, we would prefer to not have to do this.
# unfortunately, when a kustomization installs CRDs _and_ tries
# to instantiate instances of those CRDs, it occassionally fails.

TEMP_DIR=$(mktemp -d)
kustomize build --enable-alpha-plugins --enable-exec $ADD_ONS > $TEMP_DIR/add-ons.yaml

count=0
until kubectl --kubeconfig $KUBECONFIG apply -f $TEMP_DIR/add-ons.yaml; do
  exitcode=$?
  count=$(($count + 1))
  if [ $count -lt $TRIES ]; then
    echo "retry $count/$TRIES exited $exitcode, retrying in $SLEEP seconds..."
    sleep $SLEEP
  else 
    echo "retry $count/$TRIES exited $exitcode, no more retries, exiting"
    exit $exitcode
  fi 
done