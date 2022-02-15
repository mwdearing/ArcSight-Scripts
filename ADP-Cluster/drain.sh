# Maiting script to node-restart-remote.sh on plarcma-1-0001:/root/

#The kubectl drain command works best when ran locally.

function loading () {
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
node=$(hostname -f | tr '[:upper:]' '[:lower:]')
kubectl drain $node --grace-period=120 --ignore-daemonsets=true --delete-local-data &>/dev/null &
loading
wait
