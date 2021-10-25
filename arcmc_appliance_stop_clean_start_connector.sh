#! /bin/bash
# Simple connector stop/cleanup/start on appliances
# by Michael Dearing 16/10/2021
# Added variables to simply using this script with other connectors in the future.- 16/10/2021
connector='connector_8'
agentdata='/opt/arcsight/connectors/'$connector'/current/user/agent/agentdata/'
run='/opt/arcsight/connectors/'$connector'/current/run/'
logs='/opt/arcsight/connectors/'$connector'/current/logs/'
init="arc_appliance_"$connector
echo "________________________________________________________________________________"
echo ""
echo "                           Stopping "$connector
echo "________________________________________________________________________________"
# Stopping the connector with the monit service, which usually fails so we kill connector with its stop script. Monit has to be used first or connector will be restarted automatically
/opt/local/monit/bin/monit stop $connector ; /etc/init.d/$init stop
sleep 5
echo "________________________________________________________________________________"
echo ""
echo "Cleaning Thread dumps, lock files, stale pids, and stale cache older than a day!"
echo "________________________________________________________________________________"
# Changing to various directories and cleaning stale lock/pid/cache files along with Threaddumps.
cd $agentdata && find . -mtime +1 -exec rm {} \; && cd $run && rm -f a* && cd ../logs/ && rm -f T* && rm -f HeapDump*
sleep 2
echo "________________________________________________________________________________"
echo ""
echo "        Starting "$connector" and tailing the agent.out.wrapper logs"
echo "________________________________________________________________________________"
echo ""
echo ""
echo ""
# Starting the connector from the monit service and then tailing the log file.
/opt/local/monit/bin/monit start $connector ; sleep 5 ; tail -F $logs/agent.out.wrapper.log
