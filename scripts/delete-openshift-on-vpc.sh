#!/bin/bash

# **************** Global variables

# ***************** for your configuration
# *** IBM Cloud locations
source ./.env

# ***************** don't change
export VPC_ID=""
export SUBNET_ID=""
export DEFAULT_NETWORK_ACL_ID=""
export DEFAULT_ROUTING_TABLE_ID=""
export DEFAULT_SECURITY_GROUP_ID=""
export TMP_VPC_CONFIG=tmp-vpc-configuration.json
export TMP_SUBNETS=tmp-subnets.json
export TMP_ZONE=tmp-zone.json
export TMP_PUBLICGATEWAY=tmp-public-gateway.json

# *** Object Storage
export TMP_OBJECT_STORAGE=tmp-objectstorage.json

# *** Cluster
export TMP_CLUSTER=tmp-cluster.json

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
    
    ibmcloud is public-gateway $PUBLIC_GATEWAY --output json > ./$TMP_PUBLICGATEWAY
    PUBLICGATEWAY_ID=$(cat ./$TMP_PUBLICGATEWAY | jq '.id' | sed 's/"//g')
    rm -f ./$TMP_PUBLICGATEWAY
    echo "-> Delete Public Gateway : $PUBLIC_GATEWAY"
    ibmcloud is public-gateway-delete $PUBLICGATEWAY_ID --vpc $VPC_ID  --force

    echo "-> Delete Subnet: $SUBNET_NAME"
    ibmcloud is subnet-delete $SUBNET_NAME --vpc $VPC_ID --force
    
    echo "-> Verify the Public Gateway $PUBLIC_GATEWAY doesn't exists anymore"
    ibmcloud is public-gateway $PUBLIC_GATEWAY --vpc $VPC_ID 
    
    echo "-> Delete Virtual Private Cloud : $VPC_ID"
    ibmcloud is vpc-delete $VPC_ID --force
}

function deleteObjectStorage() {  
  echo "-> Delete Object Storage: $OBJECT_STORAGE_INSTANCE"  
  ibmcloud resource service-instance-delete $OBJECT_STORAGE_INSTANCE \
                                            -g $RESOURCE_GROUP \
                                            -f
}

function deleteOpenShiftCluster() {

  echo "-> Delete OpenShift cluster: $OPENSHIFT_CLUSTER_NAME"  
  ibmcloud ks cluster rm --cluster $OPENSHIFT_CLUSTER_NAME -f --force-delete-storage 
}

# **********************************************************************************
# Execution
# **********************************************************************************

getVPCconfig
echo "<-- PRESS ANY KEY"
read

deleteOpenShiftCluster
echo "<-- PRESS ANY KEY"
read

deleteVPC
echo "<-- PRESS ANY KEY"
read

deleteObjectStorage
echo "<-- PRESS ANY KEY"
read

