# ArcSight Scripts
Useful scripts for dealing with Micro Focus' ArcSight products.
## SmartConnectors
* sclb_stop_start.sh -> Used to quicky stop and start the ArcSight Loadbalancing SmartConnector.
* appliance_sc_stop_start.sh -> Used to quickly stop and start a ArcSight SmartConnector Container on a ArcMC Appliance.

    ```bash
    $ ./container_restart_menu.sh 
    1- Test_Message
    2- Temporary Connector
    3- UDP 101 (515 LB)
    4- Temporary Connector
    5- Test_Categorization
    6- SF_KAFKA_TEST
    7- Temporary Connector
    8- UDP99
    9- Exit
    Enter the number: 
    ```


## ADP Cluster
* node-restart-remote.sh -> Used with ArcSight ADP Cluster ver. 2021
    * drain.sh -> mating script to node-restart-remote.sh and goes locally on each node in /root/

    ```bash
    $ ./node-reboot-remote.sh
    ```
    

* node-cmd-sender.sh -> Used to send the same linux command to each node in the cluster.
    ```bash
    $ ./node-cmd-sender.sh ls
    node1:
    file1
    file2
    file3
    CMD:'ls' completed successfully on node1

    node2:
    file1
    file2
    file3
    CMD:'ls' completed successfully on node2
    ```
