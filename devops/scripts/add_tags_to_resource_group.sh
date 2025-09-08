#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tag-rg.sh <resource-group> key1=value1 [key2=value2 ...]
# Options:
#   --include-rg   Also tag the resource group object itself.

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <resource-group> key1=value1 [key2=value2 ...] [--include-rg]"
  exit 1
fi

RESOURCE_GROUP="$1"
shift

INCLUDE_RG=false
TAG_KVS=()

# Parse args: collect key=value pairs; detect --include-rg
for arg in "$@"; do
  if [ "$arg" = "--include-rg" ]; then
    INCLUDE_RG=true
  else
    # Basic validation: must contain '=' and non-empty key
    if [[ "$arg" != *=* || -z "${arg%%=*}" ]]; then
      echo "Invalid tag format: '$arg' (expected key=value)."
      exit 1
    fi
    TAG_KVS+=("$arg")
  fi
done

if [ "${#TAG_KVS[@]}" -eq 0 ]; then
  echo "No tags provided. Supply at least one key=value pair."
  exit 1
fi

echo "Resource group: $RESOURCE_GROUP"
echo "Tags to merge:  ${TAG_KVS[*]}"
$INCLUDE_RG && echo "Will also tag the resource group object."

timestamp() { date +'%Y-%m-%dT%H:%M:%S%z'; }
log_info() { echo "[$(timestamp)] [INFO]  $*"; }
log_warn() { echo "[$(timestamp)] [WARN]  $*" >&2; }
log_error() { echo "[$(timestamp)] [ERROR] $*" >&2; }

echo "Fetching resource IDs..."
RESOURCE_IDS=$(az resource list --resource-group "$RESOURCE_GROUP" --query "[].id" -o tsv)

if [ -z "$RESOURCE_IDS" ]; then
  echo "No resources found in resource group: $RESOURCE_GROUP"
else
  echo "Tagging resources (merge mode)..."
  # Track failures
  FAILED_RESOURCES=()
  SUCCESS_COUNT=0
  TOTAL_COUNT=0
  while IFS= read -r RESOURCE_ID; do
    [ -z "$RESOURCE_ID" ] && continue
    TOTAL_COUNT=$((TOTAL_COUNT+1))
    echo "  -> $RESOURCE_ID"
    if az resource tag \
      --ids "$RESOURCE_ID" \
      --is-incremental \
      --tags "${TAG_KVS[@]}" >/dev/null 2>&1; then
        SUCCESS_COUNT=$((SUCCESS_COUNT+1))
        log_info "Tagged $RESOURCE_ID"
    else
        log_error "Failed to tag $RESOURCE_ID"
        FAILED_RESOURCES+=("$RESOURCE_ID")
    fi
  done <<< "$RESOURCE_IDS"
  echo "Resource tagging complete: $SUCCESS_COUNT succeeded / $TOTAL_COUNT total"
fi

if $INCLUDE_RG; then
  echo "Tagging the resource group object (merge mode)..."
  RG_ID=$(az group show -n "$RESOURCE_GROUP" --query id -o tsv)
  if az resource tag \
    --ids "$RG_ID" \
    --is-incremental \
    --tags "${TAG_KVS[@]}" >/dev/null 2>&1; then
      log_info "Tagged resource group object $RG_ID"
    else
      log_error "Failed to tag resource group object $RG_ID"
      FAILED_RESOURCES+=("$RG_ID")
    fi
fi

if [ "${#FAILED_RESOURCES[@]}" -gt 0 ]; then
  echo
  log_warn "Tagging completed with failures (${#FAILED_RESOURCES[@]} resources failed):"
  for rid in "${FAILED_RESOURCES[@]}"; do
    echo "  - $rid"
  done
  echo "Exit code set to 1 due to failures."
  exit 1
else
  echo "✅ Done. All resources tagged successfully."
fi
