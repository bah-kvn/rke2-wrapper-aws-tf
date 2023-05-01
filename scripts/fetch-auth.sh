#!/bin/bash

set -e

eval "$(jq -r '@sh "K=\(.kubeconfig)"')"

host=$(yq '.clusters[0].cluster.server' $K)
client_certificate=$(yq '.users[0].user.client-certificate-data' $K)
client_key=$(yq '.users[0].user.client-key-data' $K)
cluster_ca_certificate=$(yq '.clusters[0].cluster.certificate-authority-data' $K)

jq -n \
--arg host $host \
--arg client_certificate $client_certificate \
--arg client_key $client_key \
--arg cluster_ca_certificate $cluster_ca_certificate \
'{
  "host": $host,
  "client_certificate": $client_certificate,
  "client_key": $client_key,
  "cluster_ca_certificate": $cluster_ca_certificate
}'