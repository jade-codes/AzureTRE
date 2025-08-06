variable "DOCKER_REGISTRY" {
  default = ""
}

variable "API_VERSION" {
  default = "0.24.7"
}

variable "ROOT_CLIENT_ID" {
  default = ""
}

variable "ROOT_TENANT_ID" {
  default = ""
}

variable "TRE_APPLICATION_ID" {
  default = "api://"
}

variable "TRE_URL" {
  default = "https://my-tre.northeurope.cloudapp.azure.com/api"
}

variable "POLLING_DELAY_MILLISECONDS" {
  default = 10000
}

variable "TRE_ID" {
  default = "my-tre"
}

variable "DEBUG" {
  default = false
}

variable "VERSION" {
  default = "0.0.0"
}

variable "ACTIVE_DIRECTORY_URI" {
  default = ""
}

variable "USER_MANAGEMENT_ENABLED" {
  default = false
}

variable "UI_SITE_NAME" {
  default = "Azure TRE"
}

variable "UI_FOOTER_TEXT" {
  default = "Azure Trusted Research Environment"
}


group "default" {
  targets = ["api", "ui"]
}


target "_common" {
  args = {
    BUILD_DATE = formatdate("D MMMM YYYY", timestamp())
#    BUILDKIT_SBOM_SCAN_STAGE = "true"
  }

#  attest = [
#    "type=provenance,mode=max",
#    "type=sbom"
#  ]
}


target "api" {
  inherits   = ["_common"]
  context = "api_app"
  tags       = [ "${DOCKER_REGISTRY}${DOCKER_REGISTRY != "" ? "/" : ""}tre/api:${API_VERSION}" ]
  args       = {
    API_VERSION = "${API_VERSION}"
  }
}

target "ui" {
  inherits   = ["_common"]
  context = "ui"
  tags       = [ "${DOCKER_REGISTRY}${DOCKER_REGISTRY != "" ? "/" : ""}tre/ui:${API_VERSION}" ]
  args       = {
    API_VERSION                = "${API_VERSION}"
    TRE_ID                     = "${TRE_ID}"
    ROOT_CLIENT_ID             = "${ROOT_CLIENT_ID}"
    ROOT_TENANT_ID             = "${ROOT_TENANT_ID}"
    TRE_APPLICATION_ID         = "${TRE_APPLICATION_ID}"
    TRE_URL                    = "${TRE_URL}"
    POLLING_DELAY_MILLISECONDS = "${POLLING_DELAY_MILLISECONDS}"
    DEBUG                      = "${DEBUG}"
    VERSION                    = "${VERSION}"
    ACTIVE_DIRECTORY_URI       = "${ACTIVE_DIRECTORY_URI}"
    USER_MANAGEMENT_ENABLED    = "${USER_MANAGEMENT_ENABLED}"
    UI_SITE_NAME               = "${UI_SITE_NAME}"
    UI_FOOTER_TEXT             = "${UI_FOOTER_TEXT}"
  }
}