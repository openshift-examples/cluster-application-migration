#!/usr/bin/env bash

# set -x 
set -euo pipefail

NAMESPACE=migration-demo-$(date +%s)

echo "# Create project/namespace ${NAMESPACE}"

oc new-project $NAMESPACE >/dev/null
oc label namespace/$NAMESPACE demo=migration

for file in ??-*.yaml ; do 
  echo "# Apply $file";
  oc apply -n $NAMESPACE -f $file;
done

echo "# Deploy cakephp-mysql-persistent template"
oc new-app -n $NAMESPACE cakephp-mysql-persistent


# Jenkins!!
# jenkins-ephemeral-template



# oc delete project --wait=false -l demo=migration