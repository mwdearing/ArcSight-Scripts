#!/usr/bin/env bash
# This script is used to restart a node within a MicroFocus ADP CDF ver. 2021 (Calls scripts that only exist within this k8s install)
# The normal k8s process of restarting a node is too aggressive for the kafka pieces within TransformationHub.
# The kube-stop and kube-restart scripts included within this k8s install are also too aggressive when pod eviction. 
#
#
#
# Taking the FQDN and converting it from uppercase to lowercase as the 
# kubectl drain command is case sensitive. 
upper=$(hostname -f)
node=$(echo "$upper" | tr '[:upper:]' '[:lower:]')
#
#
loading () {
    # A loop to create a spinning cursor to show progress.
    # '$!' represents the PID for the last command ran. 'sp' are the various characters used for the animation.
    # When each cmd is ran and assigned a PID, that PID exists as a folder under /proc/, thus
    # the 'while loop' will continue to loop as long as that folder exists
    # You insert this funtion to run after the command you want to have a spinning cursor for. -MD
    PID=$!
    i=1
    sp="/-\|"
    echo -n "Working... "
    while [ -d /proc/$PID ]
    do
        printf "\b${sp:i++%${#sp}:1}"
    done
}
#
drain () {
    # Gracefully cordoning off and draining node - original kube-stop was too aggressive with just
    # using --timeout=XXX rather than using --grace-period=XXX -MD
    kubectl cordon $node &>/dev/null &
    kubectl drain $node --grace-period=120 --ignore-daemonsets=true --delete-local-data &>/dev/null &
    loading
    wait
}
#
stopService () {
    # Simple funtion to call systemd to stop a service -MD
    systemctl stop kube-proxy kubelet docker &
    loading
    wait
    
}
#
umountkd () {
    # Can't find proof that these actions are needed but they were provided by the vendor, and with 
    # them being rather harmless, I'm including them -MD
    /opt/arcsight/kubernetes/bin/kubelet-umount-action.sh -y
    wait
    
}
#
umountnfs () {
    # Without umounting the NFS share, reboot seems to hang due to the connection not closing to NFS -MD
    umount -l -f /opt/arcsight
    wait
    
}
#
rst () {
    # Warning message then reboot action. -MD
    clear
    echo -n "Rebooting in 5 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting in 4 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting in 3 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting in 2 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting in 1 Seconds.."
    sleep 1
    clear
    echo -n "Rebooting now!!!"
    echo ""
    sleep 1
    clear
    reboot
}
#
#
# Something something calling each function below...(various echo cmds used for formatting) -M
echo "Draining $node"
drain
echo ""
echo "Stopping kube-proxy, kubelet, and docker"
stopService
echo ""
echo "Unmounting kubernetes docker and kubelet mounts"
sleep 2
umountkd
echo ""
echo "Unmounting NFS"
umountnfs
echo ""
rst
