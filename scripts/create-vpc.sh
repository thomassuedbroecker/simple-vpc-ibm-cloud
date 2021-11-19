#!/bin/bash

# **************** Global variables

# ***************** for your configuration
export RESOURCE_GROUP=default
export REGION="us-south"
export VPC_NAME="my-example-vpc"
export SUBNET_NAME="my-example-subnet-1"
export DEFAULT_NETWORK_ACL="my-default-example-acl"
export DEFAULT_ROUTING_TABLE="my-default-example-routing-table"
export DEFAULT_SECURITY_GROUP="my-default-example-security-group"
export PUBLIC_GATEWAY="my-public-gateway"

# ***************** don't change
export VPC_ID=""
export ZONE1=""
export ZONE2=""
export ZONE3=""
export DEFAULT_NETWORK_ACL_ID=""
export DEFAULT_ROUTING_TABLE_ID=""
export DEFAULT_SECURITY_GROUP_ID=""
export TMP_VPC_CONFIG=tmp-vpc-configuration.json
export TMP_SUBNETS=tmp-subnets.json
export TMP_ZONE=tmp-zone.json
export TMP_DEFAULT_NETWORK_ACL=""
export TMP_DEFAULT_ROUTING_TABLE=""
export TMP_DEFAULT_SECURITY_GROUP=""


# **********************************************************************************
# Functions definition
# **********************************************************************************

function setupCLIenv() { 
  echo "-> Setup IBM Cloud environment"
  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
}

function installIBMPlugins() {
  echo "->Install IBM Cloud CLI plugins"
  ibmcloud plugin install vpc-infrastructure
  ibmcloud plugin update
  ibmcloud plugin list
}

function createVPC() {
    echo "-> Create virtual Private Cloud: $VPC_NAME"
    ibmcloud is vpc-create $VPC_NAME --resource-group-name $RESOURCE_GROUP --output JSON
    ibmcloud is vpc $VPC_NAME --output JSON > $TMP_VPC_CONFIG
     
    VPC_ID=$(cat ./$TMP_VPC_CONFIG | jq '.id' | sed 's/"//g')
    echo "-> Extract Virtual Private Cloud ID : $VPC_ID" 

    echo "-> Extract default names"

    TMP_DEFAULT_NETWORK_ACL=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.name' | sed 's/"//g')
    DEFAULT_NETWORK_ACL_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.id' | sed 's/"//g')
    echo "- Access control list: "$TMP_DEFAULT_NETWORK_ACL
    
    TMP_DEFAULT_ROUTING_TABLE=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.name' | sed 's/"//g')
    DEFAULT_ROUTING_TABLE_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.id' | sed 's/"//g')
    echo "- Routing table: " $TMP_DEFAULT_ROUTING_TABLE
    
    TMP_DEFAULT_SECURITY_GROUP=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.name' | sed 's/"//g')
    DEFAULT_SECURITY_GROUP_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.id' | sed 's/"//g')
    echo "- Security group: " $TMP_DEFAULT_SECURITY_GROUP

    ZONE1="$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[].zone.name' | sed 's/"//g' | awk '/1/ {print $0}')"
    ZONE2="$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[].zone.name' | sed 's/"//g' | awk '/2/ {print $1}'))"
    ZONE3="$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[].zone.name' | sed 's/"//g' | awk '/3/{print $2}'))"
    
    echo "- Zones: $ZONE1 ; $ZONE2 ; $ZONE3"

    rm -f $TMP_VPC_CONFIG
}

function renameDefaultNames () {
  echo "-> Rename default names"
  ibmcloud is vpc-routing-table-update $VPC_ID $DEFAULT_ROUTING_TABLE_ID --name $DEFAULT_ROUTING_TABLE
  ibmcloud is network-acl-update  $DEFAULT_NETWORK_ACL_ID --vpc $VPC_ID --name $DEFAULT_NETWORK_ACL
  ibmcloud is security-group-update $DEFAULT_SECURITY_GROUP_ID --vpc $VPC_ID --name $DEFAULT_SECURITY_GROUP
}

function createPublicGateway () {
  echo "-> Create Public Gateway: $PUBLIC_GATEWAY and bind zone: $ZONE1"
  ibmcloud is public-gateway-create $PUBLIC_GATEWAY $VPC_ID $ZONE1 \
                                    --resource-group-name $RESOURCE_GROUP \
                                    --output JSON
}

function createSubnet () { 
  echo "-> Create Subnet: Bind VPC $VPC_ID and zone $ZONES[0]"
  ibmcloud is subnet-create "$SUBNET_NAME" "$VPC_ID" \
                            --ipv4-address-count 256 \
                            --zone "$ZONE1" \
                            --resource-group-name "$RESOURCE_GROUP"
  ibmcloud is subnet $SUBNET_NAME --vpc $VPC_ID
}


# **********************************************************************************
# Execution
# **********************************************************************************

setupCLIenv

#installIBMPlugins

createVPC

renameDefaultNames

createPublicGateway

createSubnet
