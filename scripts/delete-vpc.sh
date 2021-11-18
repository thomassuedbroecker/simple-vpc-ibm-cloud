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

# **********************************************************************************
# Functions definition
# **********************************************************************************

function getVPCconfig() {

    ibmcloud is vpc $VPC_NAME  --output JSON > $TMP_VPC_CONFIG
    VPC_ID=$(cat ./$TMP_VPC_CONFIG | jq '.id' | sed 's/"//g')

    DEFAULT_NETWORK_ACL_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.id' | sed 's/"//g')
    DEFAULT_ROUTING_TABLE_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.id' | sed 's/"//g')
    DEFAULT_SECURITY_GROUP_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.id' | sed 's/"//g')
    FIRST_ZONE=$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[0].zone.name' | sed 's/"//g')
 
    # rm -f $TMP_VPC_CONFIG   
}

function deleteVPC() {
    ibmcloud is public-gateway-delete $PUBLIC_GATEWAY --vpc $VPC_ID  --force
    ibmcloud is public-gateway $PUBLIC_GATEWAY --vpc $VPC_ID
    ibmcloud is vpc-delete $VPC_ID --force
}

# **********************************************************************************
# Execution
# **********************************************************************************

getVPCconfig

deleteVPC

