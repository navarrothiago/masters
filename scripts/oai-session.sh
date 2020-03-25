#!/bin/bash

# ==============================================
# Author: Thiago Navarro
# email: navarro.ime@gmail.com
#
# Script using tmux for  OAI - EPC components deployment automatization
#
# Prerequirements
# - OAI EPC components installation in one host
#
# TODO:
# - Export PREFIX in panes - echo 'export PREFIX=/usr/local/etc/oai' >> ~/.bashrc 
# - Bug when put commnads in new line using \ sessionSession
#=============================================

PREFIX="/usr/local/etc/oai"

#Create remote session with panes
sessionStart(){
# Initialize windowns and panes
ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
    "tmux kill-session -t $TARGET_USER-OAI 2>/dev/null; \
     set -- \$(stty size) && \
     tmux -2 new-session -d -s $TARGET_USER-OAI -x \$2 -y \$((\$1 - 1)) -n oai-cn-deployment && \
     tmux new-window -d -t '$TARGET_USER-OAI' -n term && \
     tmux split-window -t $TARGET_USER-OAI:0.0 -v && \
     tmux split-window -t $TARGET_USER-OAI:0.1 -v && \
     tmux split-window -t $TARGET_USER-OAI:0.2 -v && \
     tmux select-layout even-vertical "
# Deploy OAI core components
# Pane 0 HSS
# Pane 1 MME
# Pane 2 SPGW-C
# Pane 3 SPGW-U
ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
    "tmux send-keys -t $TARGET_USER-OAI:0.0 \
         'cd $PREFIX; \
          mkdir -p logs; \
          sudo touch $PREFIX/logs/hss.log; \
          sudo touch $PREFIX/logs/hss_stat.log; \
          sudo touch $PREFIX/logs/hss_audit.log; \
          sudo oai_hss -j $PREFIX/hss_rel14.json' C-m $TARGET_PASSWORD C-m &&
     tmux send-keys -t $TARGET_USER-OAI:0.1 \
         'sudo ip addr add 172.16.1.102/24 dev $TARGET_IFACE label $TARGET_IFACE:m11; \
          sudo ip addr add 192.168.247.102/24 dev $TARGET_IFACE label $TARGET_IFACE:m1c; \
          sudo ~/openair-cn/scripts/run_mme --config-file $PREFIX/mme.conf --set-virt-if' C-m $TARGET_PASSWORD C-m &&
     tmux send-keys -t $TARGET_USER-OAI:0.2 \
         'sudo ip addr add 172.55.55.101/24 dev $TARGET_IFACE label $TARGET_IFACE:sxc; \
          sudo ip addr add 172.58.58.102/24 dev $TARGET_IFACE label $TARGET_IFACE:s5c; \
          sudo ip addr add 172.58.58.101/24 dev $TARGET_IFACE label $TARGET_IFACE:p5c; sudo ip addr add 172.16.1.104/24 dev $TARGET_IFACE label $TARGET_IFACE:s11;  sudo spgwc -c $PREFIX/spgw_c.conf' C-m $TARGET_PASSWORD C-m &&
     tmux send-keys -t $TARGET_USER-OAI:0.3 \
         'sudo ip addr add 172.55.55.102/24 dev $TARGET_IFACE label $TARGET_IFACE:sxu; \
          sudo ip addr add 192.168.248.159/24 dev $TARGET_IFACE label $TARGET_IFACE:s1u; \
          echo '200 lte' | sudo tee --append /etc/iproute2/rt_tables; \
          sudo ip r add default via 192.168.78.245 dev $TARGET_IFACE table lte; \
          sudo ip rule add from 12.0.0.0/8 table lte; \
          sudo spgwu -c $PREFIX/spgw_u.conf' C-m $TARGET_PASSWORD C-m"
}

sessionAttach(){
    ssh -t  "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
    "tmux select-pane -t $TARGET_USER-OAI:1.0 && \
     tmux -2 attach-session -t $TARGET_USER-OAI"
 }

sessionStop(){
    ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
        "tmux send-keys -t $TARGET_USER-OAI:1.0 \
             'ps -ef | grep -e \"oai_hss\" | grep -v grep | awk '\''{print \$2}'\'' | xargs -r sudo kill -9; sudo ip addr del 172.16.1.102/24 dev $TARGET_IFACE label $TARGET_IFACE:m11; sudo ip addr del 192.168.247.102/24 dev $TARGET_IFACE label $TARGET_IFACE:m1c; sudo ip addr del 172.55.55.101/24 dev $TARGET_IFACE label $TARGET_IFACE:sxc; sudo ip addr del 172.58.58.102/24 dev $TARGET_IFACE label $TARGET_IFACE:s5c; sudo ip addr del 172.58.58.101/24 dev $TARGET_IFACE label $TARGET_IFACE:p5c; sudo ip addr add 172.16.1.104/24 dev $TARGET_IFACE label $TARGET_IFACE:s11; sudo ip addr del 172.55.55.102/24 dev $TARGET_IFACE label $TARGET_IFACE:sxu; sudo ip addr del 192.168.248.159/24 dev $TARGET_IFACE label $TARGET_IFACE:s1u' C-m $TARGET_PASSWORD C-m"
}

sessionKill(){
    ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
        "sleep 3; \
         tmux kill-session -t $TARGET_USER-OAI 2>/dev/null"
}

main(){
    if [[ $# != 5 ]]; then
        >&2 echo "Invalid args! ./oai-session.sh <remote_user> <remote_ip> <remote_port> <remote_password> <remote_interface>"
        >&2 echo "e.g. ./oai-session.sh epc 127.0.0.1 2222 epc ens3"
        exit 1
    fi

    TARGET_USER=$1
    TARGET_IP=$2
    TARGET_PORT=$3
    TARGET_PASSWORD=$4
    TARGET_IFACE=$5

    sessionStart
    sessionAttach
    sessionStop
    sessionKill
}

main "$@"

