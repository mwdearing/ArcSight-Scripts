#!/bin/bash
# lb service name
connector="arc_connlb"

# If statement asks user if they want to continue knowing service will stop. If no, script exits fully.
read -p "Running this script will attempt to stop the loadbalancer connector, continue?[y/n] " -n 1 -r
echo    # If you don't move to a new line after prompts only needing one character, then shell prompts is not on new line.
if [[ ! $REPLY =~ ^[Yy]$ ]]     # Since no variable was defined at the above read prompt, we're using the default for the funtion of $REPLY \
then                            # Trying to match specific regex so only Y/y triggers the script to move forward. 
    exit 1 || return 1
fi
# Slicing and dicing the output of PS to get the two PIDs belonging to the lb service and putting them on two lines.
pid1=$(ps ax | grep /opt/arcsight | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 1)
pid2=$(ps ax | grep /opt/arcsight | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 2)

# Checking to see if variable is empty or not with '-z' option within if statement.
# If the variable is empty, we go straight to asking if service should be started. 
if [ -z "$pid1" ]; then
    read -p "Service is already offline. Start?[y/n]: " -n 1 -r answer      # Notifying user service is offline and asking to start service.
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        service $connector start; tail -F /opt/arcsight/current/logs/lb.out.wrapper.log 
    else
        exit 1 || return 1
    fi
else
    kill -9 $pid1 $pid2 ; service $connector stop > /dev/null       # Forcing the service to die as service takes too long to stop gracefully, events drop in hand off to peer.
    echo "Load Balancer Service Stopped"
    read -n 1 -p "Restart loadbalancer?[y/n]: " -n 1 -r answer      # Repeated if statement from above to miminck resarting service function
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        service $connector start; tail -F /opt/arcsight/current/logs/lb.out.wrapper.log
    else
        exit 1 || return 1
    fi
fi