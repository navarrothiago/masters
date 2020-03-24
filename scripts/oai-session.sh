#!/bin/bash

PREFIX="/usr/local/etc/oai"

#Cria a sessao tmux remota com os paineis:
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
     tmux split-window -t $TARGET_USER-OAI:0.3 -v && \
     tmux select-layout even-vertical "


# Deploy OAI core components
# Pane 0 HSS
# Pane 1 MME
# Pane 2 SPGW-C
# Pane 3 SPGW-U
ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
    "tmux send-keys -t $TARGET_USER-OAI:0.0 \
         'sudo oai_hss -j $PREFIX/hss_rel14.json' C-m $TARGET_PASSWORD C-m &&
     tmux send-keys -t $TARGET_USER-OAI:0.1 \
         'sudo ip addr add 172.16.1.102/24 dev ens3 label ens3:m11; \
          sudo ip addr add 192.168.247.102/24 dev ens3 label ens3:m1c; \
          sudo ~/openair-cn/scripts/run_mme --config-file $PREFIX/mme.conf --set-virt-if' C-m $TARGET_PASSWORD C-m &&
     tmux send-keys -t $TARGET_USER-OAI:0.2 \
         'sudo ip addr add 172.55.55.101/24 dev ens3 label ens3:sxc; \
          sudo ip addr add 172.58.58.102/24 dev ens3 label ens3:s5c; \
          sudo ip addr add 172.58.58.101/24 dev ens3 label ens3:p5c; sudo ip addr add 172.16.1.104/24 dev ens3 label ens3:s11;  sudo spgwc -c $PREFIX/spgw_c.conf' C-m $TARGET_PASSWORD C-m &&
     tmux send-keys -t $TARGET_USER-OAI:0.3 \
         'sudo ip addr add 172.55.55.102/24 dev ens3 label ens3:sxu; \
          sudo ip addr add 192.168.248.159/24 dev ens3 label ens3:s1u; \
          echo '200 lte' | sudo tee --append /etc/iproute2/rt_tables; \
          sudo ip r add default via 192.168.78.245 dev ens3 table lte; \
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
             'ps -ef | grep -e \"oai_hss\" | grep -v grep | awk '\''{print \$2}'\'' | xargs -r sudo kill -9; \
              sudo ip addr del 172.16.1.102/24 dev ens3 label ens3:m11; \
              sudo ip addr del 192.168.247.102/24 dev ens3 label ens3:m1c; \
              sudo ip addr del 172.55.55.101/24 dev ens3 label ens3:sxc; \
              sudo ip addr del 172.58.58.102/24 dev ens3 label ens3:s5c; \
              sudo ip addr del 172.58.58.101/24 dev ens3 label ens3:p5c; \ 
              sudo ip addr del 172.55.55.102/24 dev ens3 label ens3:sxu; \
              sudo ip addr del 192.168.248.159/24 dev ens3 label ens3:s1u' C-m $TARGET_PASSWORD C-m && 
         tmux kill-session -t $TARGET_USER-OAI 2>/dev/null"
}

main(){
    if [[ $# != 4 ]]; then
        echo "Invalid args"
        echo "e.g. ./oai-session.sh openair-cn  127.0.0.1 2222 openain-cn"
        exit 1
    fi

    TARGET_USER=$1
    TARGET_IP=$2
    TARGET_PORT=$3
    TARGET_PASSWORD=$4

    sessionStart
    sessionAttach
    sessionStop
}

main "$@"

