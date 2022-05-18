#!/usr/bin/env bash
#-----------------------------------------------------
#
#   ArcSight Appliance SmartConnector Restart Script
#
#   Created on: 01 MAR 2022
#   Created By: Michael Dearing
#
#   Version Notes:
#   2.2 : 13/05/2022 - Code cleanup and spelling corrections.
#
#-----------------------------------------------------
# Defining the first XML found in each folder as an item in an array.
# The XML is where the user defined connector name is stored that matches the agent name in any CEF event.
# Defining the first XML found in each folder as an item in an array.
# The XML is where the user defined connector name is stored that matches the agent name in any CEF event.
base="connector_"


# This could probably be cleaned up but due to how it was originally scripted, the array was just hard defined.
xml[0]="$(ls /opt/arcsight/connectors/connector_1/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"
xml[1]="$(ls /opt/arcsight/connectors/connector_2/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"
xml[2]="$(ls /opt/arcsight/connectors/connector_3/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"
xml[3]="$(ls /opt/arcsight/connectors/connector_4/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"
xml[4]="$(ls /opt/arcsight/connectors/connector_5/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"
xml[5]="$(ls /opt/arcsight/connectors/connector_6/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"
xml[6]="$(ls /opt/arcsight/connectors/connector_7/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"
xml[7]="$(ls /opt/arcsight/connectors/connector_8/current/user/agent/3*.xml 2>/dev/null | nl | grep -P "\s1\s" | cut -f 2)"

# Determining if each item in the array is present before running subshell command or else cat will through errors in stdout.
# Not all connectors hosts will have a full set of 8 containers, so limiting errors. 
if [[ -e ${xml[0]} ]]; then
    conname1="$(cat <"${xml[0]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname1="Empty Container"
fi
if [[ -e ${xml[1]} ]]; then
    conname2="$(cat <"${xml[1]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname2="Empty Container"
fi
if [[ -e ${xml[2]} ]]; then
    conname3="$(cat <"${xml[2]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname3="Empty Container"
fi
if [[ -e ${xml[3]} ]]; then
    conname4="$(cat <"${xml[3]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname4="Empty Container"
fi
if [[ -e ${xml[4]} ]]; then
    conname5="$(cat <"${xml[4]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname5="Empty Container"
fi
if [[ -e ${xml[5]} ]]; then
    conname6="$(cat <"${xml[5]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname6="Empty Container"
fi
if [[ -e ${xml[6]} ]]; then
    conname7="$(cat <"${xml[6]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname7="Empty Container"
fi
if [[ -e ${xml[7]} ]]; then
    conname8="$(cat <"${xml[7]}" 2>/dev/null | grep -P -m 1 "AgentName" | egrep -o 'AgentName=.*$' | cut -d '"' -f 2)"
else
    conname8="Empty Container"
fi
#-----------------------------------------------------
#                   Functions
#-----------------------------------------------------

cleanstart () {
        read -p "Which log to tail? (0)-None | (1)-agent.out.wrapper.log | (2) - agent.log: " -n 1 -r log
        tl=$(ls -alh /opt/arcsight/connectors/$connector/current/logs/T* 2>/dev/null | wc -l)
        hp=$(ls -alh /opt/arcsight/connectors/$connector/current/logs/H* 2>/dev/null | wc -l)
        bk=$(ls -alh /opt/arcsight/connectors/$connector/current/user/agent/*.bak 2>/dev/null | wc -l)
        sc=$(find /opt/arcsight/connectors/$connector/current/user/agent/agentdata/ -mtime +2 2>/dev/null | wc -l)
        rm -f /opt/arcsight/connectors/$connector/current/run/a*;
        rm -f /opt/arcsight/connectors/$connector/current/logs/T* 2>/dev/null
        rm -f /opt/arcsight/connectors/$connector/current/logs/H* 2>/dev/null
        rm -f /opt/arcsight/connectors/$connector/current/user/agent/*.bak 2>/dev/null
        find /opt/arcsight/connectors/$connector/current/user/agent/agentdata/ -mtime +2 -exec rm -f '{}' \;
        echo ""
        echo "Container Clean up summary:"
        echo "Total # of ThreadDump files removed: $tl"
        echo "Total # of HeapDump files removed: $hp"
        echo "Total # of Stale Cache files removed: $sc"
        echo "Total # of .bak files removed: $bk"
        sleep 3
        echo "Starting $connector..."
        sleep 2
        echo "Tailing $log:"
        /opt/local/monit/bin/monit start $connector
        clear
}
# Send SIGTERM to stop a container and then goes through and cleans up any files that may prevent the service from starting up again.
logset () {
    if [[ $log == 1 ]]; then
    log="$aout"
    tail -F $log;
    elif [[ $log == 0 ]]; then
    exit 0
    else
    log="$agt"
    tail -F $log;
    fi
}
constop () {
    pid1="$(ps ax | grep $connector | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 1)"
    pid2="$(ps ax | grep $connector | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 2)"
    aout="/opt/arcsight/connectors/$connector/current/logs/agent.out.wrapper.log"
    agt="/opt/arcsight/connectors/$connector/current/logs/agent.log"
    echo
    read -p "Stopping "$connector", continue?[y/n] " -n 1 -r
    clear
    echo    # If you don't move to a new line after prompts only needing one character, then shell prompts is not on new line.
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then     # Since no variable was defined at the above read prompt, we're using the default for the funtion of $REPLY \                     
        exit 1                 # Trying to match specific regex so only Y/y triggers the script to move forward.
    fi
    if [ -z "$pid1" ]; then
    read -p "Service is already offline. Start?[y/n]: " -n 1 -r answer      # Notifying user service is offline and asking to start service.
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        cleanstart
        logset
    else
        exit 1
    fi
else
    /opt/local/monit/bin/monit stop $connector ; kill -15 $pid1 $pid2 2>/dev/null && sleep 5  # Originally was using -9 but now using SIGTERM to stop the service to die as service takes too long to stop gracefully, events drop in hand off to peer.   
    echo ""$connector" Service Stopped"
    read -n 1 -p "Restart "$connector"?[y/n]: " -n 1 -r answer            # Repeated if statement from above to miminck resarting service function
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        cleanstart
        logset 
    else
        exit 1
    fi
fi
}

#-----------------------------------------------------
#                   Execution
#-----------------------------------------------------

# Determining if variable has a value before trying to print it or else we're just printing a new line
clear
echo "1- $conname1"
echo "2- $conname2"
echo "3- $conname3"
echo "4- $conname4"
echo "5- $conname5"
echo "6- $conname6"
echo "7- $conname7"
echo "8- $conname8"
echo "9- Exit"

# Prompting user for selection in upcoming case statement.
read -p "Enter the number: " -n 1 -r num
# Catconating to strings together to form the full connector service name and then issuing the constop function.
while [[ -z $num ]]; do
    read -p "Please Enter a number (1-8): " -n 1 -r num
done
case $num in
        1) connector="$base$num"; constop ;;
        2) connector="$base$num"; constop ;;
        3) connector="$base$num"; constop ;;
        4) connector="$base$num"; constop ;;
        5) connector="$base$num"; constop ;;
        6) connector="$base$num"; constop ;;
        7) connector="$base$num"; constop ;;
        8) connector="$base$num"; constop ;;
        9) echo; echo "Exiting..."; sleep .5; exit 0  ;; 
        *) echo; echo "Invalid Selection"; exit 1 ;;
esac
