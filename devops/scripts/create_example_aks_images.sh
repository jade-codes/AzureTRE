#!/bin/bash
# filepath: /workspaces/AzureTRE/devops/scripts/create_example_aks_images.sh
set -e

# Require ACR_NAME and ACR_FQDN to be set in the environment
if [ -z "$ACR_NAME" ] || [ -z "$ACR_FQDN" ]; then
  echo "Error: ACR_NAME and ACR_FQDN environment variables must be set."
  exit 1
fi

GITEA_IMAGE="gitea"
HELLO_IMAGE="hello-world"
GITEA_TAG="latest"
HELLO_TAG="latest"

# Login to ACR using short name
az acr login --name "$ACR_NAME"

# Build and push Gitea example (using official image as base)
docker pull gitea/gitea:"$GITEA_TAG"
docker tag gitea/gitea:"$GITEA_TAG" "$ACR_FQDN/microsoft/azuretre/example/$GITEA_IMAGE:$GITEA_TAG"
docker push "$ACR_FQDN/microsoft/azuretre/example/$GITEA_IMAGE:$GITEA_TAG"

# Build and push Hello World example (using http-echo)
docker pull hashicorp/http-echo:"$HELLO_TAG"
docker tag hashicorp/http-echo:"$HELLO_TAG" "$ACR_FQDN/microsoft/azuretre/example/$HELLO_IMAGE:$HELLO_TAG"
docker push "$ACR_FQDN/microsoft/azuretre/example/$HELLO_IMAGE:$HELLO_TAG"

echo "Images pushed:"
echo "$ACR_FQDN/microsoft/azuretre/example/$GITEA_IMAGE:$GITEA_TAG"
echo "$ACR_FQDN/microsoft/azuretre/example/$HELLO_IMAGE:$HELLO_TAG"
