#!/bin/bash

# ==============================================
# Author: Thiago Navarro
# email: navarro.ime@gmail.com
#
# Script for deployment OAI VMs
#
# Packages required: tmux, kvm, qemu, virsh
#
# TODO:
#=============================================

TMUX_SESSION="work-session"

#Create remote session with panes
sessionStart(){
    # Initialize windowns and panes
    tmux kill-session -t $TMUX_SESSION 2>/dev/null 
    tmux -2 new-session -d -s $TMUX_SESSION 
    tmux new-window -d -t $TMUX_SESSION -n epc
    tmux new-window -d -t $TMUX_SESSION -n jupyter 
    tmux new-window -d -t $TMUX_SESSION -n tat 
    tmux split-window -t $TMUX_SESSION:0.0 -v 
    tmux select-layout even-vertical 
    tmux send-keys -t $TMUX_SESSION:0.0 "virsh --connect qemu:///system start $HOSTNAME_EPC; sleep 10; ssh -X -o ConnectTimeout=10 epc@$IP_EPC -t " C-m 
    #tmux send-keys -t $TMUX_SESSION:0.1 "virsh --connect qemu:///system start enodeb; sleep 10; ssh -o ConnectTimeout=10 enodeb@192.168.11.15 -t " C-m 
    tmux send-keys -t $TMUX_SESSION:0.1 "ssh -X $HOSTNAME_ENODEB@$IP_ENODEB" C-m 
    tmux send-keys -t $TMUX_SESSION:2.0 "/usr/local/etc/anaconda3/bin/jupyter notebook --notebook-dir=/work/unicamp/masters --no-browser" C-m 
    tmux send-keys -t $TMUX_SESSION:3.0 "tat /work/unicamp/masters/scripts/logs/192.168.15.14-mme-link.log /Filters:/work/unicamp/masters/tat-filters/oai-epc-filter.tat" C-m 
}

sessionAttach(){
    tmux select-pane -t $TMUX_SESSION:0.0 
    tmux -2 attach-session -t $TMUX_SESSION
 }

sessionStop(){
    tmux send-keys -t $TMUX_SESSION:1.0 "virsh --connect qemu:///system shutdown $HOSTNAME_EPC" C-m 
    #tmux send-keys -t $TMUX_SESSION:1.1 "virsh --connect qemu:///system shutdown $HOSTNAME_ENODEB" C-m 
}

sessionKill(){
    sleep 1
    tmux kill-session -t $TMUX_SESSION 2>/dev/null
}

main(){
    if [[ $# != 4 ]]; then
        >&2 echo "TODO!! "
        >&2 echo "e.g. ./vms-session epc 127.0.0.1 enodeb 127.0.0.2"
        exit 1
    fi
    #echo -n Password:
    #read -s PASSWORD
    HOSTNAME_EPC=$1
    IP_EPC=$2
    HOSTNAME_ENODEB=$3
    IP_ENODEB=$4

    sessionStart
    sessionAttach
    sessionStop
    sessionKill
}

main "$@"

