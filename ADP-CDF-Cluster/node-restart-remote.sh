#!/usr/bin/env bash
#-----------------------------------------------
#
#   MF CDF Node Reboot Script
#
#   Created on: 12 FEB 2022
#   Created By: Michael Dearing
#
#   Version Notes:
#   2.0 : 12/02/2022 - Remotely reboot worker and other masternodes from plarcma-1-0001.thrivent.com
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
# Time-out value for manual intervention of uncordoning node.
kubeletdeadline=300
nodes=(
    'node1.com'
    'node2.com'
    'node3.com'
    'node4.com'
    )
node=""
#
#---------------#
#   User Input  #
#---------------#
#
# Selection Menu - no need for input validation.
clear 
echo "It's important that you start with the Master Nodes"
PS3="Select the node you wish to restart: "
 select host in ${nodes[@]}; do
    node=$host
    break
done
#
#-----------#
# Functions #
#-----------#
#
# Check function is simply looping over the ping commands output to determine whether hosts is pingable based on commands response.
function check() {
    count=60
                               
    while [[ $count -ne 0 ]]; do
        ping="$(ping -c 1 $node)"                   
        rc=$?
        if [[ $rc -eq 0 ]]; then
            count=1                    
        else
            sleep 1                         
        fi
        count=$count-1                
    done
    if [[ $rc -eq 0 ]]; then
        echo 
        echo "$node is back online"
    else
        echo 
        echo "$node didn't come up. Exiting"
        exit 1
    fi  
}
#
# Using kubectl to verify that the host is in a "Ready" state after rebooting. 
function kubeletrdy() {
  i=0
  while [[ $i -lt $kubeletdeadline ]]; do
    status=$(kubectl get node $node -o "jsonpath={.status.conditions[?(.reason==\"KubeletReady\")].type}" 2>/dev/null)
    if [[ "$status" == "Ready" ]]; then
      echo
      echo "KubeletReady after $i seconds"
      break;
    else
      i=$(($i+10))
      sleep 10
      echo "$node NotReady - waited $i seconds"
    fi
  done
  if [[ $i == $kubeletdeadline ]]; then
    echo "Error: Did not reach KubeletReady state within $kubeletdeadline seconds. Script now exiting!!"
    echo
    echo "Uncordon $node manually!!!"
    exit 1
  fi
}
#
# Executing a separate script that's locally on the node to drain said node.
function drain () {
    # Gracefully cordoning off and draining node - original kube-stop was too aggressive with just
    # using --timeout=XXX rather than using --grace-period=XXX -MD
    # kubectl cordon $node &>/dev/null &
    ssh $node "nohup /root/drain.sh"
    wait
    # 
}
#
# Simple funtion to call systemd to stop a service
function stopService () {
    ssh $node 'nohup systemctl stop kube-proxy kubelet docker'
    # loading
    wait
}
#
# Can't find proof that these actions are needed but they were provided by the vendor, and with 
# them being rather harmless, I'm including them
function umountkd () {
    ssh $node 'nohup /opt/arcsight/kubernetes/bin/kubelet-umount-action.sh -y'
    wait
}
#
# Without umounting the NFS share, reboot seems to hang due to the connection not closing to NFS
function umountnfs () {
    ssh $node 'nohup umount -l -f /opt/arcsight'
    wait
}
#
# Warning message then reboot action.
function rst () {
    clear
    echo -n "Rebooting $node in 5 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting $node in 4 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting $node in 3 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting $node in 2 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting $node in 1 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting $node now!!!"
    echo ""
    sleep 1
    clear
    ssh $node 'reboot'
}
#
# Uncordoning the node after reboot.
function uncordon(){
    kubectl uncordon $node
}
#
#---------------#
#   Execution   #
#---------------#
#
# After verifying node, execution steps begin.
clear
proof="$(kubectl get nodes | grep $node 2>/dev/null)"
echo "Draining $node"
drain
echo 
echo "Stopping kube-proxy, kubelet, and docker on $node"
stopService
echo 
echo "Unmounting kubernetes docker and kubelet mounts on $node"
sleep 2
umountkd
echo 
echo "Unmounting NFS from $node"
sleep 1
umountnfs
echo 
rst
echo
echo "Waiting for $node to complete reboot cycle"
sleep 10 # Making sure the node has gone down fully before doing ping checks
check
echo
echo "Uncordoning $node"
sleep 1
uncordon
echo
echo "Checking node status"
echo
kubeletrdy
echo
echo "---------------------------------------------------------------------------------------------"
echo "The reboot of $node is now fully complete and is now accepting new pods"
echo "---------------------------------------------------------------------------------------------"
echo
echo "$proof"
echo
sleep 1
exit 0
