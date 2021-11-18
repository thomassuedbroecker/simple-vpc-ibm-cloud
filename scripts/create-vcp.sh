#!/bin/bash

# **************** Global variables

export RESOURCE_GROUP=default
export REGION="us-south"

# **********************************************************************************
# Functions definition
# **********************************************************************************

function setupCLIenv() {
  
  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION
 
}

# **********************************************************************************
# Execution
# **********************************************************************************

setupCLIenv()