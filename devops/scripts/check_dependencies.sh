#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
# Uncomment this line to see each command for debugging (careful: this will show secrets!)
# set -o xtrace

# Get the directory that this script is in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo -e "\n\e[34m╔══════════════════════════════════════╗"
echo -e "║          \e[33mAzure TRE Makefile\e[34m          ║"
echo -e "╚══════════════════════════════════════╝"

echo -e "\n\e[34m»»» ✅ \e[96mChecking pre-reqs\e[0m..."

echo -e "\n\e[96mChecking for Azure CLI\e[0m..."
if ! command -v az &> /dev/null; then
  echo -e "\e[31m»»» ⚠️ Azure CLI is not installed! 😥 Please go to http://aka.ms/cli to set it up or rebuild your devcontainer"
  exit 1
fi


if [[ "${1:-?}" == *"env"* ]]; then
  if [ -z "${USE_ENV_VARS_NOT_FILES:-}" ]; then
    # We only do this for local builds
    echo -e "\n\e[96mLoading local environment variables\e[0m..."
    if [ ! -f "config.yaml" ]; then
      echo -e "\e[31m»»» ⚠️ Your config.yaml file has not been setup! 😥 Please create a config.yaml file."
      exit 1
    fi
    # shellcheck disable=SC1091
    . "$DIR/load_and_validate_env.sh"
  fi
fi

if [[ "${1:-?}" != *"nodocker"* ]]; then
  echo -e "\n\e[96mChecking for Docker\e[0m..."
  if ! command -v docker &> /dev/null; then
    echo -e "\e[31m»»» ⚠️ Docker is not installed! 😥 Please go to https://docs.docker.com/engine/install/ to set it up or rebuild your devcontainer"
    exit 1
  fi
fi

if  [[ "${1:-?}" == *"certbot"* ]]; then
  echo -e "\n\e[96mChecking for Certbot\e[0m..."
  if ! /opt/certbot/bin/certbot --version > /dev/null 2>&1; then
    echo -e "\e[31m»»» ⚠️ Certbot is not installed! 😥 Please go to https://certbot.eff.org/lets-encrypt/pip-other to set it up or rebuild your devcontainer"
    exit 1
  fi
fi

if [[ "${1:-?}" == *"porter"* ]]; then
  echo -e "\n\e[96mChecking for porter\e[0m..."
  if ! command -v porter &> /dev/null; then
    echo -e "\e[31m»»» ⚠️ Porter is not installed! 😥 Please go to https://porter.sh/install/ to set it up or rebuild your devcontainer"
    exit 1
  fi
fi

# This is called if we are in a CI system and we will login
# with a Service Principal.
if [ -n "${TF_IN_AUTOMATION:-}" ]; then
    az cloud set --name "$AZURE_ENVIRONMENT"

  if [ -n "${AZURE_FEDERATED_TOKEN:-}" ]; then
    az login --service-principal -u "$ARM_CLIENT_ID" --federated-token "$AZURE_FEDERATED_TOKEN" --tenant "$ARM_TENANT_ID"
  else
    az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
  fi

    az account set -s "$ARM_SUBSCRIPTION_ID"
fi

SUB_NAME=$(az account show --query name -o tsv)
SUB_ID=$(az account show --query id -o tsv)
export SUB_ID
TENANT_ID=$(az account show --query tenantId -o tsv)
export TENANT_ID

# Configure AzureRM provider and backend to use Azure AD to connect to storage accounts
export ARM_STORAGE_USE_AZUREAD=true
export ARM_USE_AZUREAD=true
export ARM_USE_OIDC=true

if [ -z "$SUB_NAME" ]; then
  echo -e "\n\e[31m»»» ⚠️ You are not logged in to Azure!"
  exit 1
fi

echo -e "\e[34m»»» 🔨 \e[96mAzure details from logged on user \e[0m"
echo -e "\e[34m»»»   • \e[96mSubscription: \e[33m$SUB_NAME\e[0m"
echo -e "\e[34m»»»   • \e[96mTenant:       \e[33m$TENANT_ID\e[0m\n"

# This shouldn't be here but since other scripts don't use this option we must reset it.
# For tracking: https://github.com/microsoft/AzureTRE/issues/1672
set +o nounset
