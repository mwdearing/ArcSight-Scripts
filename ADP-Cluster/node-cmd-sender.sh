#!/usr/bin/env bash
#-----------------------------------------------
#
#   Run the same command across all worker nodes.
#
#   Created on: 15 FEB 2022
#   Created By: Michael Dearing
#
#   Version Notes:
#   1.0 : 12/02/2022 - 
#
#-----------------------------------------------
# This script is used to restart a node within a MicroFocus ADP CDF ver. 2021 (Calls scripts that only exist within this k8s install)
# The normal k8s process of restarting a node is too aggressive for the kafka pieces within TransformationHub.
# The kube-stop and kube-restart scripts included within this k8s install are also too aggressive when pod eviction. 
#
#
#
#
#-----------------------#
#   Global Variables    #   
#-----------------------#
#

nodes=(
    'node1'
    'node2'
    'node3'
    'node4'
    'node5'
    )

for node in ${nodes[@]}; do
    if ping -c 1 $node &>/dev/null; then
        cmd="$node '$*'"
        if ssh $cmd 2>/dev/null; then
            echo "CMD:'$*' completed successfully on $node"
        else
            echo "CMD:'$*' failed on $node"
        fi
        sleep 1
        echo
    fi
done
