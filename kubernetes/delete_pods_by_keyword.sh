#!/usr/bin/env bash
ns=arcsight-installer-xxxx
read -p "Enter keyword of a group of pods to delete (e.g. fusion-, th-, kafkamanager,): " keywd
kubectl get pods -A -owide | grep $ns | grep $keywd | awk '{print $2}' | xargs kubectl delete pod -o name -n $ns
