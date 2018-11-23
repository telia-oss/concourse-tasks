#!/bin/sh
set -euo pipefail
if [ -z $service ]; then
  echo "service is a required parameter and must be set."
  exit 1
fi
if [ -z $cluster ]; then
  echo "cluster is a required parameter and must be set."
  exit 1
fi

function get_counts () {
  inputjson=`aws ecs describe-services --services $service --cluster $cluster`
  mainversion=`echo $inputjson |jq -r '.services[].taskDefinition'`
  running_count=`echo $inputjson |jq --arg mainversion "$mainversion" '.services[].deployments[] | select (.taskDefinition==$mainversion) | .runningCount'`
  desired_count=`echo $inputjson |jq --arg mainversion "$mainversion" '.services[].deployments[] | select (.taskDefinition==$mainversion) | .desiredCount'`
}

get_counts
echo  -n "Waiting for service deployment to complete "
while [ "$running_count" -lt "$desired_count" ]; do
  echo -n "."
  sleep 5
  get_counts
done
echo " Done!"