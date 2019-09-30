#!/usr/bin/env bash

#######################################
# Install chaincode on peer(s) provided specified parameters
# Globals:
#   None
# Arguments:
#   - $1: ORG: org msp name
#   - $2: ADMIN_IDENTITY: abs path to associated admin identity
#   - $3: CONN_PROFILE: abs path to the connection profile
#   - $4: CC_NAME: chaincode name to be installed
#   - $5: CC_VERSION: chaincode version to be installed
#   - $6: PLATFORM: [ golang, node, java ]
#   - $7: SRC_DIR: absolute path to chaincode directory
# Returns:
#   None
#######################################
function install_fabric_chaincode {
  local ORG=$1
  local ADMIN_IDENTITY=$2
  local CONN_PROFILE=$3
  local CC_NAME=$4
  local CC_VERSION=$5
  local PLATFORM=$6
  local SRC_DIR=$7

  local CMD="fabric-cli chaincode install --conn-profile ${CONN_PROFILE} --org ${ORG} \
  --admin-identity ${ADMIN_IDENTITY} --cc-name ${CC_NAME} --cc-version ${CC_VERSION} \
  --cc-type ${PLATFORM} --src-dir ${SRC_DIR}"

  echo ">>> ${CMD}"
  echo "${CMD}" | bash
}