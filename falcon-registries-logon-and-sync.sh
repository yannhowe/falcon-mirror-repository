echo "Getting Bearer Token"
export FALCON_CID_NO_CHECKSUM=$(echo $FALCON_CID | awk -F'-' '{print $1}')
export FALCON_API_BEARER_TOKEN=$(curl \
--silent \
--header "Content-Type: application/x-www-form-urlencoded" \
--data "client_id=${FALCON_CLIENT_ID}&client_secret=${FALCON_CLIENT_SECRET}" \
--request POST \
--url "https://$FALCON_CLOUD_API/oauth2/token" | \
jq -r '.access_token')

echo "KPA Registry"
echo "**Getting Credentials"
FALCON_KPA_DOCKERAPITOKEN=$(curl -sL -X GET "https://${FALCON_CLOUD_API}/kubernetes-protection/entities/integration/agent/v1?cluster_name=clustername&is_self_managed_cluster=true" -H "Accept: application/yaml" -H "Authorization: Bearer ${FALCON_API_BEARER_TOKEN}" | awk '/dockerAPIToken:/ {print $2}')
echo "**Logging into registry"
echo "$FALCON_KPA_DOCKERAPITOKEN" | skopeo login --username kp-$FALCON_CID_NO_CHECKSUM --password-stdin $FALCON_CONTAINER_REGISTRY
echo "Sync Images"
skopeo -v
skopeo sync --src docker --dest docker $FALCON_CONTAINER_REGISTRY/kubernetes_protection/kpagent $YOUR_REGISTRY

echo "Sensor Registry"
echo "**Getting Credentials"
FALCON_CONTAINER_SENSOR_DOCKERAPITOKEN=$(curl -sL -X GET "https://${FALCON_CLOUD_API}/container-security/entities/image-registry-credentials/v1" -H "authorization: Bearer ${FALCON_API_BEARER_TOKEN}" | awk '/token/ {print $2}' | tr -d '"')
echo "**Logging into registry"
echo "$FALCON_CONTAINER_SENSOR_DOCKERAPITOKEN" | skopeo login --username fc-$FALCON_CID_NO_CHECKSUM --password-stdin $FALCON_CONTAINER_REGISTRY
echo "Sync Images"
skopeo sync --src docker --dest docker "$FALCON_CONTAINER_REGISTRY/falcon-sensor/us-2/release/falcon-sensor" $YOUR_REGISTRY
skopeo sync --src docker --dest docker "$FALCON_CONTAINER_REGISTRY/falcon-container/us-2/release/falcon-sensor" $YOUR_REGISTRY
