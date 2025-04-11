#!/bin/bash

set -e

ACCESS_TOKEN=$(curl https://hub.docker.com/v2/auth/token -s -X POST -H "Content-type: application/json" -d "{\"identifier\":\"${DOCKERHUB_USERNAME}\",\"secret\":\"${DOCKERHUB_TOKEN}\"}" | jq .access_token -r)
ALLOWED_REGISTRIES=$(curl "https://hub.docker.com/v2/orgs/${DOCKERHUB_ORG}/settings/registry-access-management/policy" -s -H "Authorization: Bearer $ACCESS_TOKEN" | jq -c '.allowed | map(.value)')

CONFIG_DATA="{\"mutators\":[{ \"type\": \"addLabels\", \"labels\": { \"protected\": \"true\" }}],\"gates\":[{ \"type\": \"registry\", \"registries\": ${ALLOWED_REGISTRIES} }], \"responseFilters\":[{ \"type\": \"labelFilter\", \"requiredLabels\": { \"protected\": \"true\" }}]}"

echo "Config data: ${CONFIG_DATA}"

mv /var/run/docker.sock /var/run/docker.sock.orig

docker -H unix:///var/run/docker.sock.orig run \
    -dv /var/run:/var/run \
    -e LISTEN_SOCKET_PATH=/var/run/docker.sock \
    -e CONFIG_DATA="${CONFIG_DATA}" \
    -e FORWARDING_SOCKET_PATH=/var/run/docker.sock.orig \
    mikesir87/docker-socket-proxy
