#!/bin/bash

# **************** Global variables

# **************** Global variables

# ***************** for your configuration
# *** IBM Cloud locations
export RESOURCE_GROUP=default
export REGION="us-south"

# *** VPC
export VPC_NAME="my-openshift-vpc"
export SUBNET_NAME="my-openshift-subnet-1"
export DEFAULT_NETWORK_ACL="my-default-openshift-acl"
export DEFAULT_ROUTING_TABLE="my-default-openshift-routing-table"
export DEFAULT_SECURITY_GROUP="my-default-openshift-security-group"
export PUBLIC_GATEWAY="my-openshift-public-gateway"

# *** Object Storage
export OBJECT_STOARGE_INSTANCE="vpc-openshift-cos"
export OBJECT_STOARGE_PLAN="standard"
export OBJECT_STOARGE_REGION="global"
export OBJECT_STOARGE_COS_CRN=""

# *** OpenShift

export OPENSHIFT_CLUSTER_VERSION="4.8_openshift"
export OPENSHIFT_CLUSTER_NAME="vpc-openshift-cluster"
export OPENSHIFT_WORKNODE_COUNT="3"
export OPENSHIFT_WORKNODE_FLAVOR="bx2.4x16"

# ***************** don't change
export VPC_ID=""
export SUBNET_ID=""
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
    echo "VPC ID : $VPC_ID"

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
    
    echo "-> Delete Virtual Private Cloud : $VPC_ID"
    ibmcloud is vpc-delete $VPC_ID --force
}

function deleteObjectStorage() {  
  echo "-> Delete Object Storage: $OBJECT_STOARGE_INSTANCE"  
  ibmcloud resource service-instance-delete $OBJECT_STOARGE_INSTANCE -f
}

function deleteOpenShiftCluster() {

  echo "-> Delete OpenShift cluster: $OPENSHIFT_CLUSTER_NAME"  
  ibmcloud os cluster rm --cluster $OPENSHIFT_CLUSTER_NAME -f --force-delete-storage 
}

# **********************************************************************************
# Execution
# **********************************************************************************

getVPCconfig

deleteVPC

deleteObjectStorage

