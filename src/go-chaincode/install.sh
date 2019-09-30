#!/usr/bin/env bash

echo "######## Install cds chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain.sh"

$DEBUG && set -x

if [[ ! -f $CONFIGPATH ]]; then
  echo "No deploy configuration at specified path: ${CONFIGPATH}"
  exit 1
fi

echo "======== Validating dependencies ========"
nvm_install_node "${NODE_VERSION}"

echo "-------- Building Fabric-Cli --------"
build_fabric_cli "${FABRIC_CLI_DIR}"

echo "-------- Installing jq --------"
install_jq

# Load profiles from toolchain ENV variables (from creation)
echo "======== Loading identity profiles and certificates ========"
PROFILES_PATH=$(mktemp -d)
mkdir -p "${PROFILES_PATH}"

# handle single identity/certificate or an array of information
if [[ ${ADMIN_IDENTITY_STRING::1} != "[" ]]; then
    ADMIN_IDENTITY_STRING=["$ADMIN_IDENTITY_STRING"]
fi
for IDENTITYINDEX in $(jq -n "${ADMIN_IDENTITY_STRING}" | jq -r "keys | .[]"); do
    jq -n "${ADMIN_IDENTITY_STRING}" | jq -r ".[$IDENTITYINDEX]" | tee "${PROFILES_PATH}/ADMINIDENTITY_${IDENTITYINDEX}.json"

    echo "-> ${PROFILES_PATH}/ADMINIDENTITY_${IDENTITYINDEX}.json"
done

if [[ ${CONNECTION_PROFILE_STRING::1} != "[" ]]; then
    CONNECTION_PROFILE_STRING=["$CONNECTION_PROFILE_STRING"]
fi
for PROFILEINDEX in $(jq -n "${CONNECTION_PROFILE_STRING}" | jq -r "keys | .[]"); do
    jq -n "${CONNECTION_PROFILE_STRING}" | jq -r ".[$PROFILEINDEX]" | tee "${PROFILES_PATH}/CONNPROFILE_${PROFILEINDEX}.json"

    echo "-> ${PROFILES_PATH}/CONNPROFILE_${PROFILEINDEX}.json"
done

# Deploying based on configuration options
echo "######### Reading 'deploy_config.json' for deployment options #########"
ECODE=1
for ORG in $(jq -r "keys | .[]" "${CONFIGPATH}"); do    
  for CCINDEX in $(jq -r ".[\"${ORG}\"].chaincode | keys | .[]" "${CONFIGPATH}"); do
    CC=$(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}]" "${CONFIGPATH}")    

    # collect chaincode metadata
    CC_NAME=$(jq -n "${CC}" | jq -r '.name')
    CC_VERSION="$(date '+%Y%m%d.%H%M%S')"
    json_version=$(jq -n "${CC}" | jq -r '.version?')
    if [[ $json_version != null && $json_version != "" ]]; then
        CC_VERSION=$json_version
    fi
    CC_SRC=$(jq -n "${CC}" | jq -r '.path')

    ADMIN_IDENTITY_FILE="${PROFILES_PATH}/ADMINIDENTITY_0.json"
    CONN_PROFILE_FILE="${PROFILES_PATH}/CONNPROFILE_0.json"

    # should install
    if [[ "true" == $(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .install" "${CONFIGPATH}") ]]; then
        install_fabric_chaincode "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" \
          "${CC_NAME}" "${CC_VERSION}" "golang" "${CC_SRC}"
    fi

    ECODE=0
  done
done

rm -rf "${PROFILES_PATH}"

if [[ ! $ECODE ]]; then error_exit "ERROR: please check the deploy_config.json to set deploy jobs"; fi