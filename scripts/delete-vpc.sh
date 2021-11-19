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
export DEFAULT_NETWORK_ACL_ID=""
export DEFAULT_ROUTING_TABLE_ID=""
export DEFAULT_SECURITY_GROUP_ID=""
export TMP_VPC_CONFIG=tmp-vpc-configuration.json

# **********************************************************************************
# Functions definition
# **********************************************************************************

function getVPCconfig() {
    echo "Get the configuration for the Virtual Private Cloud $VPC_NAME"
    ibmcloud is vpc $VPC_NAME  --output JSON > $TMP_VPC_CONFIG
    VPC_ID=$(cat ./$TMP_VPC_CONFIG | jq '.id' | sed 's/"//g')

    DEFAULT_NETWORK_ACL_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.id' | sed 's/"//g')
    DEFAULT_ROUTING_TABLE_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.id' | sed 's/"//g')
    DEFAULT_SECURITY_GROUP_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.id' | sed 's/"//g')
    FIRST_ZONE=$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[0].zone.name' | sed 's/"//g')
 
    rm -f $TMP_VPC_CONFIG   
}

function deleteVPC() {
    
    echo "-> Delete Subnet: $SUBNET_NAME"
    ibmcloud is subnet-delete $SUBNET_NAME --vpc $VPC_ID 
    
    echo "-> Delete Public Gateway : $PUBLIC_GATEWAY"
    ibmcloud is public-gateway-delete $PUBLIC_GATEWAY --vpc $VPC_ID  --force
    
    echo "-> Verify the Public Gateway $PUBLIC_GATEWAY doesn't exists anymore"
    ibmcloud is public-gateway $PUBLIC_GATEWAY --vpc $VPC_ID
    
    echo "-> Delete Virtual Private Cloud"
    ibmcloud is vpc-delete $VPC_ID --force
}

# **********************************************************************************
# Execution
# **********************************************************************************

getVPCconfig

deleteVPC

