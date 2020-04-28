#!/usr/bin/env bash

# set -x 
set -euo pipefail

NAMESPACE=migration-demo-$(date +%s)

echo "# Create project/namespace ${NAMESPACE}"

oc new-project $NAMESPACE >/dev/null
oc label namespace/$NAMESPACE demo=migration

oc new-app -n ${NAMESPACE} nginx-example

for file in ??-*.yaml ; do 
  echo "# Apply $file";
  oc apply -n $NAMESPACE -f $file;
done

echo "# Start nodejs build pipeline"
oc start-build -n $NAMESPACE nodejs-sample-pipeline

echo "# Deploy wordpress"
oc create \
  -n $NAMESPACE \
  -f https://raw.githubusercontent.com/openshift-examples/wordpress-quickstart/master/templates/classic-standalone.json

oc new-app -n $NAMESPACE \
  --template=wordpress-classic-standalone \
  -p APPLICATION_NAME="wordpress-demo" \
  -p QUICKSTART_REPOSITORY_URL="https://github.com/openshift-examples/wordpress-quickstart.git"

WORPRESS=$(oc get route wordpress-demo -o jsonpath='{.spec.host}')

echo "# Configure wordpress: http://${WORPRESS}/wp-admin/install.php?step=2"

set +e
echo -n "Configure wordpress.."
while true  # infinite loop
do
    curl "http://${WORPRESS}/wp-admin/install.php?step=2" \
      -o /dev/null -s --fail \
      --data-urlencode "weblog_title=WordpressDemo" \
      --data-urlencode "user_name=admin" \
      --data-urlencode "admin_email=admin@example.com" \
      --data-urlencode "admin_password=redhat02" \
      --data-urlencode "admin_password2=redhat02" \
      --data-urlencode "pw_weak=1"
    if [ $? -eq 0 ]
    then
        # curl didn't return 0 - failure
        break # terminate loop
    fi
    echo -en "."   # display # of requests each iteration
    sleep 1  # short pause between requests
done

echo " wordpress is ready!"
set -e
