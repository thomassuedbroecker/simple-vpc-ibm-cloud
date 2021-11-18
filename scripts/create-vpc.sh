#!/bin/bash

# **************** Global variables

export RESOURCE_GROUP=default
export REGION="us-south"
export VPC_NAME="my-example-vpc"
export VPC_ID=""
export FIRST_ZONE=""
export DEFAULT_NETWORK_ACL="my-default-example-acl"
export DEFAULT_ROUTING_TABLE="my-default-example-routing-table"
export DEFAULT_SECURITY_GROUP="my-default-example-security-group"
export PUBLIC_GATEWAY="my-public-gateway"
export DEFAULT_NETWORK_ACL_ID=""
export DEFAULT_ROUTING_TABLE_ID=""
export DEFAULT_SECURITY_GROUP_ID=""


export TMP_VPC_CONFIG=tmp-vpc-configuration.json
export TMP_DEFAULT_NETWORK_ACL=""
export TMP_DEFAULT_ROUTING_TABLE=""
export TMP_DEFAULT_SECURITY_GROUP=""


# **********************************************************************************
# Functions definition
# **********************************************************************************

function setupCLIenv() { 
  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
}

function installPlugins() {
  ibmcloud plugin install vpc-infrastructure
  ibmcloud plugin update
  ibmcloud plugin list
}

function createVPC() {
    ibmcloud is vpc-create $VPC_NAME --resource-group-name $RESOURCE_GROUP --output JSON
    ibmcloud is vpc $VPC_NAME --output JSON > $TMP_VPC_CONFIG

    VPC_ID=$(cat ./$TMP_VPC_CONFIG | jq '.id' | sed 's/"//g')

    echo "Extract default names: "
    
    TMP_DEFAULT_NETWORK_ACL=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.name' | sed 's/"//g')
    DEFAULT_NETWORK_ACL_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.id' | sed 's/"//g')
    echo "- Access control list: "$TMP_DEFAULT_NETWORK_ACL
    
    TMP_DEFAULT_ROUTING_TABLE=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.name' | sed 's/"//g')
    DEFAULT_ROUTING_TABLE_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.id' | sed 's/"//g')
    echo "- Routing table: " $TMP_DEFAULT_ROUTING_TABLE
    
    TMP_DEFAULT_SECURITY_GROUP=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.name' | sed 's/"//g')
    DEFAULT_SECURITY_GROUP_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.id' | sed 's/"//g')
    echo "- Security group: " $TMP_DEFAULT_SECURITY_GROUP
    
    FIRST_ZONE=$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[0].zone.name' | sed 's/"//g')
    echo "- Zone : " $FIRST_ZONE

    rm -f $TMP_VPC_CONFIG
}

function renameDefaults () {
    ibmcloud is vpc-routing-table-update $VPC_ID $DEFAULT_ROUTING_TABLE_ID --name $DEFAULT_NETWORK_ACL
    ibmcloud is network-acl-update  $DEFAULT_NETWORK_ACL_ID --vpc $VPC_ID --name $DEFAULT_NETWORK_ACL
    ibmcloud is security-group-update $DEFAULT_SECURITY_GROUP_ID --vpc $VPC_ID --name $DEFAULT_SECURITY_GROUP
}

function createPublicGateway () {
  ibmcloud is public-gateway-create $PUBLIC_GATEWAY $VPC_ID $FIRST_ZONE --resource-group-name $RESOURCE_GROUP --output JSON
}

# **********************************************************************************
# Execution
# **********************************************************************************

setupCLIenv

#installPlugins

createVPC

renameDefaults

createPublicGateway



