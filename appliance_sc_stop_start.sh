#!/bin/bash
# Gather container number from user
read -n 1 -p "Enter Container Number(0-9): " num
echo
base="connector_"
connector="$base$num"

read -p "Running this script will stop "$connector", continue?[y/n] " -n 1 -r
echo    # If you don't move to a new line after prompts only needing one character, then shell prompts is not on new line.
if [[ ! $REPLY =~ ^[Yy]$ ]]     # Since no variable was defined at the above read prompt, we're using the default for the funtion of $REPLY \
then                            # Trying to match specific regex so only Y/y triggers the script to move forward. 
    exit 1 || return 1
fi
 
pid1=$(ps ax | grep $connector | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 1)
pid2=$(ps ax | grep $connector | grep -v grep | awk '{print $1}' | sed 'N;s/\n/,/' | cut -d "," -f 2)

if [ -z "$pid1" ]; then
    read -p "Service is already offline. Start?[y/n]: " -n 1 -r answer      # Notifying user service is offline and asking to start service.
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        rm -f /opt/arcsight/connectors/$connector/current/run/a*; rm -f rm -f /opt/arcsight/connectors/$connector/current/logs/T*
        /opt/local/monit/bin/monit start $connector; tail -F /opt/arcsight/connectors/$connector/current/logs/agent.out.wrapper.log 
    else
        exit 1 || return 1
    fi
else
    /opt/local/monit/bin/monit stop $connector ; kill -9 $pid1 $pid2 && sleep 2     # Forcing the service to die as service takes too long to stop gracefully, events drop in hand off to peer.
    echo ""$connector" Service Stopped"
    read -n 1 -p "Restart "$connector"?[y/n]: " -n 1 -r answer            # Repeated if statement from above to miminck resarting service function
    echo
    if [[ $answer =~ ^[Yy]$ ]]; then
        rm -f /opt/arcsight/connectors/$connector/current/run/a*; rm -f rm -f /opt/arcsight/connectors/$connector/current/logs/T*
        /opt/local/monit/bin/monit start $connector; tail -F /opt/arcsight/connectors/$connector/current/logs/agent.out.wrapper.log
    else
        exit 1 || return 1
    fi
fi
