#!/bin/bash

# FYI: Made with vpc-infrastructure[infrastructure-service] 3.4.0 plugin version

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
export OBJECT_STORAGE_INSTANCE="vpc-openshift-cos"
export OBJECT_STORAGE_PLAN="standard"
export OBJECT_STORAGE_REGION="global"
export OBJECT_STORAGE_COS_CRN=""

# *** OpenShift
export OPENSHIFT_CLUSTER_VERSION="4.8_openshift"
export OPENSHIFT_CLUSTER_NAME="vpc-openshift-cluster"
export OPENSHIFT_WORKNODE_COUNT="2"
export OPENSHIFT_WORKNODE_FLAVOR="bx2.4x16"
export OPENSHIFT_ENTITLEMENT="cloud_pak"

# ***************** don't change

# *** VPC
export VPC_ID=""
export SUBNET_ID=""
export PUBLICGATEWAY_ID=""
export ZONE1=""
export ZONE2=""
export ZONE3=""
export DEFAULT_NETWORK_ACL_ID=""
export DEFAULT_ROUTING_TABLE_ID=""
export DEFAULT_SECURITY_GROUP_ID=""
export TMP_DEFAULT_NETWORK_ACL=""
export TMP_DEFAULT_ROUTING_TABLE=""
export TMP_DEFAULT_SECURITY_GROUP=""

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

function setupCLIenv() {
    echo "-> ------------------------------------------------------------"
    echo "-  Setup IBM Cloud environment"
    echo "-> ------------------------------------------------------------"

    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
}

function installIBMPlugins() {
    echo "-> ------------------------------------------------------------"
    echo "- Install IBM Cloud CLI plugins"
    echo "-> ------------------------------------------------------------"

    ibmcloud plugin install vpc-infrastructure
    #ibmcloud plugin install infrastructure-service
    ibmcloud plugin install kubernetes-service
    ibmcloud plugin update
    ibmcloud plugin list
}

function installJQwithBrew() {
    echo "-> ------------------------------------------------------------"
    echo "- Install jq to utilies json input and output"
    echo "-> ------------------------------------------------------------"

    brew update
    brew install jq
}

function createVPC() {
    echo "-> ------------------------------------------------------------"
    echo "-  Create virtual Private Cloud: $VPC_NAME"
    echo "-> ------------------------------------------------------------"

    ibmcloud is vpc-create $VPC_NAME --resource-group-name $RESOURCE_GROUP --output JSON
    ibmcloud is vpc $VPC_NAME --output JSON > $TMP_VPC_CONFIG
     
    VPC_ID=$(cat ./$TMP_VPC_CONFIG | jq '.id' | sed 's/"//g')
    echo "-> ------------------------------------------------------------"
    echo "-  Extract Virtual Private Cloud ID : $VPC_ID" 
    echo "-> ------------------------------------------------------------"

    echo "-> ------------------------------------------------------------"
    echo "-  Extract default names"
    echo "-> ------------------------------------------------------------"

    TMP_DEFAULT_NETWORK_ACL=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.name' | sed 's/"//g')
    DEFAULT_NETWORK_ACL_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_network_acl.id' | sed 's/"//g')
    echo "-> ------------------------------------------------------------"
    echo "- Access control list: "$TMP_DEFAULT_NETWORK_ACL
    echo "-> ------------------------------------------------------------"
    
    TMP_DEFAULT_ROUTING_TABLE=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.name' | sed 's/"//g')
    DEFAULT_ROUTING_TABLE_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_routing_table.id' | sed 's/"//g')
    echo "-> ------------------------------------------------------------"
    echo "- Routing table: " $TMP_DEFAULT_ROUTING_TABLE
    echo "-> ------------------------------------------------------------"
    
    TMP_DEFAULT_SECURITY_GROUP=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.name' | sed 's/"//g')
    DEFAULT_SECURITY_GROUP_ID=$(cat ./$TMP_VPC_CONFIG | jq '.default_security_group.id' | sed 's/"//g')
    echo "-> ------------------------------------------------------------"
    echo "- Security group: " $TMP_DEFAULT_SECURITY_GROUP
    echo "-> ------------------------------------------------------------"

    ZONE1="$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[].zone.name' | sed 's/"//g' | awk '/1/ {print $0}')"
    ZONE2="$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[].zone.name' | sed 's/"//g' | awk '/2/ {print $1}')"
    ZONE3="$(cat ./$TMP_VPC_CONFIG | jq '.cse_source_ips[].zone.name' | sed 's/"//g' | awk '/3/ {print $2}')"
    
    echo "-> ------------------------------------------------------------"
    echo "- Zones: $ZONE1 ; $ZONE2 ; $ZONE3"
    echo "-> ------------------------------------------------------------"

    rm -f $TMP_VPC_CONFIG
}

function renameDefaultNames () {
    echo "-> ------------------------------------------------------------"
    echo "-> Rename default names"
    echo "-> ------------------------------------------------------------"
    #ibmcloud is vpc-routing-table $VPC_ID $DEFAULT_ROUTING_TABLE_ID --vpc $VPC_ID --output json
    ibmcloud is vpc-routing-table-update $VPC_ID $DEFAULT_ROUTING_TABLE_ID --name $DEFAULT_ROUTING_TABLE
    
    #ibmcloud is network-acl $DEFAULT_NETWORK_ACL_ID --vpc $VPC_ID --output json
    ibmcloud is network-acl-update  $DEFAULT_NETWORK_ACL_ID --vpc $VPC_ID --name $DEFAULT_NETWORK_ACL
    
    #ibmcloud is security-group $DEFAULT_SECURITY_GROUP_ID --vpc $VPC_ID  --output json
    ibmcloud is security-group-update $DEFAULT_SECURITY_GROUP_ID --vpc $VPC_ID --name $DEFAULT_SECURITY_GROUP
}

function createPublicGateway () {
    echo "-> ------------------------------------------------------------"
    echo "-  Create Public Gateway: $PUBLIC_GATEWAY and bind zone: $ZONE1"
    echo "-> ------------------------------------------------------------"
    ibmcloud is public-gateway-create $PUBLIC_GATEWAY $VPC_ID $ZONE1 \
                                      --resource-group-name $RESOURCE_GROUP \
                                      --output JSON

    ibmcloud is public-gateway $PUBLIC_GATEWAY --output json > ./$TMP_PUBLICGATEWAY
    PUBLICGATEWAY_ID=$(cat ./$TMP_PUBLICGATEWAY | jq '.id' | sed 's/"//g')
    rm -f ./$TMP_PUBLICGATEWAY
}

function createSubnet () { 
    echo "-> ------------------------------------------------------------"
    echo "-  Create Subnet: Bind VPC $VPC_ID and zone $ZONE1"
    echo "-> ------------------------------------------------------------"
    ibmcloud is subnet-create "$SUBNET_NAME" "$VPC_ID" \
                              --ipv4-address-count 256 \
                              --zone "$ZONE1" \
                              --resource-group-name "$RESOURCE_GROUP"
    ibmcloud is subnet $SUBNET_NAME --vpc $VPC_ID --output json > ./$TMP_SUBNETS
    SUBNET_ID=$(cat ./$TMP_SUBNETS | jq '.id' | sed 's/"//g')
    echo "-> ------------------------------------------------------------"
    echo "-  Subnet ID : $SUBNET_ID"
    echo "-> ------------------------------------------------------------"

    echo "-> ------------------------------------------------------------"
    echo "-  Attach Public Gateway ($PUBLICGATEWAY_ID) to Subnet ($SUBNET_NAME)"
    echo "-> ------------------------------------------------------------"  
    ibmcloud is subnet-update $SUBNET_NAME --pgw $PUBLICGATEWAY_ID

    rm -f ./$TMP_SUBNETS
}

function createObjectStorage () {

    echo "-> ------------------------------------------------------------"
    echo "-  Create Object Storage: $OBJECT_STORAGE_INSTANCE"
    echo "-> ------------------------------------------------------------"

    ibmcloud resource service-instance-create $OBJECT_STORAGE_INSTANCE cloud-object-storage $OBJECT_STORAGE_PLAN $OBJECT_STORAGE_REGION
    ibmcloud resource service-instance $OBJECT_STORAGE_INSTANCE --output json > ./$TMP_OBJECT_STORAGE
    OBJECT_STORAGE_COS_CRN=$(cat ./$TMP_OBJECT_STORAGE | jq '.[].crn' | sed 's/"//g')
    #echo " OBJECT_Storage CRN : $OBJECT_STORAGE_COS_CRN"
    rm -f ./$TMP_OBJECT_STORAGE
}

function createOpenShiftCluster() {
 
    echo "-> ------------------------------------------------------------"
    echo "-> Create OpenShift cluster: $OPENSHIFT_CLUSTER_NAME"
    echo "-> ------------------------------------------------------------"
    ibmcloud oc cluster create vpc-gen2 --name $OPENSHIFT_CLUSTER_NAME \
                                        --zone $ZONE1 \
                                        --version $OPENSHIFT_CLUSTER_VERSION \
                                        --flavor $OPENSHIFT_WORKNODE_FLAVOR \
                                        --workers $OPENSHIFT_WORKNODE_COUNT \
                                        --vpc-id $VPC_ID \
                                        --subnet-id $SUBNET_ID \
                                        --cos-instance $OBJECT_STORAGE_COS_CRN \
                                        --entitlement $OPENSHIFT_ENTITLEMENT

    echo "-> ------------------------------------------------------------"
    echo "-  Details of the OpenShift cluster: $OPENSHIFT_CLUSTER_NAME"
    echo "-> ------------------------------------------------------------"
    ibmcloud oc cluster get --cluster $OPENSHIFT_CLUSTER_NAME \
                            --output json > ./$TMP_CLUSTER
    rm -f ./$TMP_CLUSTER
    CLUSTER_STATUS=$(cat ./$TMP_CLUSTER | jq '.status' | sed 's/"//g')
    CLUSTER_STATE=$(cat ./$TMP_CLUSTER | jq '.state' | sed 's/"//g')
    CLUSTER_ID=$(cat ./$TMP_CLUSTER | jq '.id' | sed 's/"//g')
    echo "- Cluster status : $CLUSTER_STATUS"
    echo "- Cluster state  : $CLUSTER_STATE"
    echo "- Cluster id     : $CLUSTER_ID"
    URL="https://cloud.ibm.com/kubernetes/clusters/$CLUSTER_ID"
    echo "- IBM Cloud Web UI: $URL"
    open "$URL"
}

# **********************************************************************************
# Execution
# **********************************************************************************

setupCLIenv
echo "<-- PRESS ANY KEY"
read

#installIBMPlugins
#echo "<-- PRESS ANY KEY"
#read

createVPC
echo "<-- PRESS ANY KEY"
read

renameDefaultNames
echo "<-- PRESS ANY KEY"
read

createPublicGateway
echo "<-- PRESS ANY KEY"
read

createSubnet
echo "<-- PRESS ANY KEY"
read

createObjectStorage
echo "<-- PRESS ANY KEY"
read

createOpenShiftCluster
echo "<-- PRESS ANY KEY"
read
