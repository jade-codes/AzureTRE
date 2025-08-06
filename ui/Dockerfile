ARG API_VERSION
ARG BUILD_DATE

FROM mcr.microsoft.com/azurelinux/base/nodejs:20 AS build

ARG ROOT_CLIENT_ID=""
ARG ROOT_TENANT_ID=""
ARG TRE_APPLICATION_ID="api://"
ARG TRE_URL="https://my-tre.northeurope.cloudapp.azure.com/api"
ARG POLLING_DELAY_MILLISECONDS=10000
ARG TRE_ID="my-tre"
ARG DEBUG=false
ARG VERSION="0.0.0"
ARG ACTIVE_DIRECTORY_URI=""
ARG USER_MANAGEMENT_ENABLED=false
ARG UI_SITE_NAME="Azure TRE"
ARG UI_FOOTER_TEXT="Azure Trusted Research Environment"

RUN tdnf install -y jq
COPY /app /app

WORKDIR /app

RUN jq --arg rootClientId "$ROOT_CLIENT_ID" \
    --arg rootTenantId "$ROOT_TENANT_ID" \
    --arg treApplicationId "$TRE_APPLICATION_ID" \
    --arg treUrl "$TRE_URL" \
    --argjson pollingDelayMilliseconds "$POLLING_DELAY_MILLISECONDS" \
    --arg treId "$TRE_ID" \
    --arg debug "$DEBUG" \
    --arg version "$VERSION" \
    --arg activeDirectoryUri "$ACTIVE_DIRECTORY_URI" \
    --argjson userManagementEnabled "$USER_MANAGEMENT_ENABLED" \
    --arg uiSiteName "$UI_SITE_NAME" \
    --arg uiFooterText "$UI_FOOTER_TEXT" \
    '.rootClientId |= $rootClientId | \
     .rootTenantId |= $rootTenantId | \
     .treApplicationId |= $treApplicationId | \
     .treUrl |= $treUrl | \
     .pollingDelayMilliseconds |= $pollingDelayMilliseconds | \
     .treId |= $treId | \
     .debug |= ($debug | test("true")) | \
     .version |= $version | \
     .activeDirectoryUri |= $activeDirectoryUri | \
     .userManagementEnabled |= $userManagementEnabled | \
     .uiSiteName |= $uiSiteName | \
     .uiFooterText |= $uiFooterText' src/config.source.json > src/config.json

RUN jq '.' src/config.json

RUN npm install
RUN npm run build

RUN mkdir -p /etc/nginx/client_body_temp

FROM mcr.microsoft.com/azurelinux/base/nginx:1

ARG API_VERSION
ARG BUILD_DATE

LABEL org.opencontainers.image.authors="Microsoft ISE" \
      org.label-schema.build-date="${BUILD_DATE}"

COPY --from=build --chown=nginx:nginx /app/dist /usr/share/nginx/html
