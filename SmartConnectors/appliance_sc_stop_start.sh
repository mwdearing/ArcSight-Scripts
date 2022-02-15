#!/usr/bin/env bash
# Defining the first XML found in each folder as an item in an array.
# The XML is where the user defined connector name is stored that matches the agent name in any CEF event.
base="connector_"

# This could probably be cleaned up but due to how it was originally scripted, the array was just hard defined.
xml[0]="$(ls /opt/arcsight/connectors/connector_1/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"
xml[1]="$(ls /opt/arcsight/connectors/connector_2/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"
xml[2]="$(ls /opt/arcsight/connectors/connector_3/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"
xml[3]="$(ls /opt/arcsight/connectors/connector_4/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"
xml[4]="$(ls /opt/arcsight/connectors/connector_5/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"
xml[5]="$(ls /opt/arcsight/connectors/connector_6/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"
xml[6]="$(ls /opt/arcsight/connectors/connector_7/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"
xml[7]="$(ls /opt/arcsight/connectors/connector_8/current/user/agent/3*.xml | nl | grep -P "\s1\s" | cut -f 2)"

# Determining if each item in the array is present before running subshell command or else cat will through errors in stdout.
# Not all connectors hosts will have a full set of 8 containers, so limiting errors. 
if [[ -e ${xml[0]} ]]; then
    conname1="$(cat <"${xml[0]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname1="Empty Container"
fi
if [[ -e ${xml[1]} ]]; then
    conname2="$(cat <"${xml[1]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname2="Empty Container"
fi
if [[ -e ${xml[2]} ]]; then
    conname3="$(cat <"${xml[2]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname3="Empty Container"
fi
if [[ -e ${xml[3]} ]]; then
    conname4="$(cat <"${xml[3]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname4="Empty Container"
fi
if [[ -e ${xml[4]} ]]; then
    conname5="$(cat <"${xml[4]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname5="Empty Container"
fi
if [[ -e ${xml[5]} ]]; then
    conname6="$(cat <"${xml[5]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname6="Empty Container"
fi
if [[ -e ${xml[6]} ]]; then
    conname7="$(cat <"${xml[6]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname7="Empty Container"
fi
if [[ -e ${xml[7]} ]]; then
    conname8="$(cat <"${xml[7]}" | grep -P -m 1 "AgentName" | cut -d '"' -f 2)"
else
    conname8="Empty Container"
fi
#-----------------------------------------------------
#                   Functions
#-----------------------------------------------------

# Loading Animation 
loading () {
    # A loop to create a spinning cursor to show progress.
    # '$!' represents the PID for the last command ran. 'sp' are the various characters used for the animation.
    # When each cmd is ran and assigned a PID, that PID exists as a folder under /proc/, thus
    # the 'while loop' will continue to loop as long as that folder exists
    # You insert this funtion to run after the command you want to have a spinning cursor for. -MD
    PID=$!
    i=1
    sp="/-\|"
    echo -n "Stopping $connector... "
    while [ -d /proc/$PID ]
    do
        printf "\b${sp:i++%${#sp}:1}"
    done
}
# Send SIGTERM to stop a container and then goes through and cleans up any files that may prevent the service from starting up again.
constop () {
    pid1="$(ps ax | grep $connector | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 1)"
    pid2="$(ps ax | grep $connector | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 2)"
    echo
    read -p "You're about to stop "$connector", continue?[y/n] " -n 1 -r
    echo    # If you don't move to a new line after prompts only needing one character, then shell prompts is not on new line.
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then     # Since no variable was defined at the above read prompt, we're using the default for the funtion of $REPLY \                     
        exit 1                 # Trying to match specific regex so only Y/y triggers the script to move forward.
    fi
    if [ -z "$pid1" ]; then
    read -p "Service is already offline. Start?[y/n]: " -n 1 -r answer      # Notifying user service is offline and asking to start service.
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        rm -f /opt/arcsight/connectors/$connector/current/run/a*; rm -f rm -f /opt/arcsight/connectors/$connector/current/logs/T*
        /opt/local/monit/bin/monit start $connector; tail -F /opt/arcsight/connectors/$connector/current/logs/agent.out.wrapper.log;
    else
        exit 1
    fi
else
    /opt/local/monit/bin/monit stop $connector ; kill -15 $pid1 $pid2 && sleep 2  # Originally was using -9 but now using SIGTERM to stop the service to die as service takes too long to stop gracefully, events drop in hand off to peer.   
    echo ""$connector" Service Stopped"
    read -n 1 -p "Restart "$connector"?[y/n]: " -n 1 -r answer            # Repeated if statement from above to miminck resarting service function
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        rm -f /opt/arcsight/connectors/$connector/current/run/a*; rm -f rm -f /opt/arcsight/connectors/$connector/current/logs/T*
        /opt/local/monit/bin/monit start $connector; tail -F /opt/arcsight/connectors/$connector/current/logs/agent.out.wrapper.log;
    else
        exit 1
    fi
fi
}

#-----------------------------------------------------
#                   Execution
#-----------------------------------------------------

# Determining if variable has a value before trying to print it or else we're just printing a new line
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
