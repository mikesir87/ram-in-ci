#!/bin/bash

set -e

ACCESS_TOKEN=$(curl https://hub.docker.com/v2/auth/token -s -X POST -H "Content-type: application/json" -d "{\"identifier\":\"${DOCKERHUB_USERNAME}\",\"secret\":\"${DOCKERHUB_TOKEN}\"}" | jq .access_token -r)
ALLOWED_REGISTRIES=$(curl "https://hub.docker.com/v2/orgs/${DOCKERHUB_ORG}/settings/registry-access-management/policy" -s -H "Authorization: Bearer $ACCESS_TOKEN" | jq -c '.allowed | map(.value)')

CONFIG_DATA="{\"mutators\":[{ \"type\": \"addLabels\", \"labels\": { \"protected\": \"true\" }}],\"gates\":[{ \"type\": \"registry\", \"registries\": ${ALLOWED_REGISTRIES} }], \"responseFilters\":[{ \"type\": \"labelFilter\", \"requiredLabels\": { \"protected\": \"true\" }}]}"

echo "Config data"
echo $CONFIG_DATA

mkdir /tmp/docker-socket

docker run \
    -e CONFIG_DATA="${CONFIG_DATA}" \
    -dv /var/run/docker.sock:/var/run/docker.sock \
    -v /tmp/docker-socket:/tmp/docker-socket \
    -e LISTEN_SOCKET_PATH=/tmp/docker-socket/docker.sock \
    mikesir87/docker-socket-proxy

echo "DOCKER_HOST=unix:///tmp/docker-socket/docker.sock" >> $GITHUB_ENV