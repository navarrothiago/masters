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

#The "canonical" way (on Bash + Linux) to get the actual source directory:
SRCHOME=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")

PREFIX="/usr/local/etc/oai"
CASSANDRA_SERVER_IP='127.0.0.1'

LOGS_DIR=$SRCHOME/logs

#Copy logs (hss, mme, spgwc, spgwu) to host
copyLogs(){
    NOW=$(date +"%F--%H-%M-%S")
    FOLDER_NAME=log-"$NOW".log
    HSS_LOGFILE="$TARGET_IP"-"hss-$NOW.log"
    MME_LOGFILE="$TARGET_IP"-"mme-$NOW.log"
    SPGWU_LOGFILE="$TARGET_IP"-"spgwu-$NOW.log"
    SPGWC_LOGFILE="$TARGET_IP"-"spgwc-$NOW.log"

    mkdir -p "$SRCHOME"/logs/"$FOLDER_NAME"

    scp "$TARGET_USER"@"$TARGET_IP":~/logs/hss.log "$LOGS_DIR"/"$FOLDER_NAME"/"$HSS_LOGFILE" &
    COPY_HSS_LOG_PID=$!
    scp "$TARGET_USER"@"$TARGET_IP":~/logs/mme.log "$LOGS_DIR"/"$FOLDER_NAME"/"$MME_LOGFILE" &
    COPY_MME_LOG_PID=$!
    scp "$TARGET_USER"@"$TARGET_IP":~/logs/spgwu.log "$LOGS_DIR"/"$FOLDER_NAME"/"$SPGWU_LOGFILE" &
    COPY_SPGWU_LOG_PID=$!
    scp "$TARGET_USER"@"$TARGET_IP":~/logs/spgwc.log "$LOGS_DIR"/"$FOLDER_NAME"/"$SPGWC_LOGFILE" &
    COPY_SPGWC_LOG_PID=$!
   
    wait "$COPY_HSS_LOG_PID"
    wait "$COPY_MME_LOG_PID"
    wait "$COPY_SPGWU_LOG_PID"
    wait "$COPY_SPGWC_LOG_PID"

    ln -sf "$LOGS_DIR"/"$FOLDER_NAME"/"$HSS_LOGFILE" "$LOGS_DIR"/"$TARGET_IP"-hss-link.log
    ln -sf "$LOGS_DIR"/"$FOLDER_NAME"/"$MME_LOGFILE" "$LOGS_DIR"/"$TARGET_IP"-mme-link.log
    ln -sf "$LOGS_DIR"/"$FOLDER_NAME"/"$SPGWU_LOGFILE" "$LOGS_DIR"/"$TARGET_IP"-spgwu-link.log
    ln -sf "$LOGS_DIR"/"$FOLDER_NAME"/"$SPGWC_LOGFILE" "$LOGS_DIR"/"$TARGET_IP"-spgwc-link.log
}

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
         tmux select-layout even-vertical"

    #Create log folder if not exist
    ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
        "tmux send-keys -t $TARGET_USER-OAI:0.0 'mkdir ~/logs' C-m $TARGET_PASSWORD C-m"

    #Deploy OAI core components
    #
    #Pane 0 
    #- Create logs
    #- Populate table
    #- Run oai_hss
    #
    #Pane 1 MME
    #- Create interfaces
    #- Run run_mme
    #
    #Pane 2 SPGW-C
    #- Create interfaces
    #- Run spgw_c
    #
    #Pane 3 SPGW-U
    #- Create interfaces
    #- Create routes
    #- Run spgw_u
    ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
        "tmux send-keys -t $TARGET_USER-OAI:0.0 \
             'cd $PREFIX; \
              mkdir -p logs; \
              sudo touch $PREFIX/logs/hss.log; \
              sudo touch $PREFIX/logs/hss_stat.log; \
              sudo touch $PREFIX/logs/hss_audit.log; \
              cd ~/openair-cn/scripts; \
              ./data_provisioning_users \
                  --apn oai.ipv4 \
                  --apn2 internet \
                  --key BA6C4204C5F5F77726C0B43431C92EEF \
                  --imsi-first 724990000001046 \
                  --msisdn-first 15126389698 \
                  --mme-identity mme.openairinterface.org \
                  --no-of-users 1 \
                  --realm openairinterface.org \
                  --truncate True \
                  --verbose True \
                  --cassandra-cluster $CASSANDRA_SERVER_IP; \
              ./data_provisioning_users \
                  --apn oai.ipv4 \
                  --apn2 internet \
                  --key 92127CD2BA85A9FB0079BB3EC8453AF2 \
                  --imsi-first 724990000001047 \
                  --msisdn-first 15126389698 \
                  --mme-identity mme.openairinterface.org \
                  --no-of-users 1 \
                  --realm openairinterface.org \
                  --truncate False \
                  --verbose True \
                  --cassandra-cluster $CASSANDRA_SERVER_IP; \
              ./data_provisioning_users \
                  --apn oai.ipv4 \
                  --apn2 internet \
                  --key 53C21A405FB6E86A15539B2B76D078F8 \
                  --imsi-first 724990000001048 \
                  --msisdn-first 15126389698 \
                  --mme-identity mme.openairinterface.org \
                  --no-of-users 1 \
                  --realm openairinterface.org \
                  --truncate False \
                  --verbose True \
                  --cassandra-cluster $CASSANDRA_SERVER_IP; \
              ./data_provisioning_users \
                  --apn oai.ipv4 \
                  --apn2 internet \
                  --key D4AA9FD8F87EED5D95D8D61871B20A7B \
                  --imsi-first 724990000001049 \
                  --msisdn-first 15126389698 \
                  --mme-identity mme.openairinterface.org \
                  --no-of-users 1 \
                  --realm openairinterface.org \
                  --truncate False \
                  --verbose True \
                  --cassandra-cluster $CASSANDRA_SERVER_IP; \
              ./data_provisioning_mme \
                  --id 3 \
                  --mme-identity mme.openairinterface.org \
                  --realm openairinterface.org \
                  --ue-reachability 1 \
                  --truncate True \
                  --verbose True \
                  -C $CASSANDRA_SERVER_IP; \
                  cd $PREFIX; \
                  sudo oai_hss -j $PREFIX/hss_rel14.json --onlyloadkey; \
                  sudo oai_hss -j $PREFIX/hss_rel14.json 2>&1 | tee ~/logs/hss.log' C-m $TARGET_PASSWORD C-m &&
         tmux send-keys -t $TARGET_USER-OAI:0.1 \
             'sleep 1; \
              sudo ip addr add 172.16.1.102/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:m11; \
              sudo ip addr add $TARGET_IP_S10 brd + dev $TARGET_IFACE label $TARGET_IFACE:m10; \
              sudo ~/openair-cn/scripts/run_mme --config-file $PREFIX/mme.conf --set-virt-if 2>&1 | tee ~/logs/mme.log' C-m $TARGET_PASSWORD C-m &&
         tmux send-keys -t $TARGET_USER-OAI:0.2 \
             'sleep 1; \
              sudo ip addr add 172.55.55.101/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:sxc; \
              sudo ip addr add 172.58.58.102/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:s5c; \
              sudo ip addr add 172.58.58.101/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:p5c; \
              sudo ip addr add 172.16.1.104/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:s11; \
              sudo -E spgwc -c $PREFIX/spgw_c.conf 2>&1 | tee ~/logs/spgwc.log' C-m $TARGET_PASSWORD C-m &&
         tmux send-keys -t $TARGET_USER-OAI:0.3 \
             'sleep 2; \
              sudo ip addr add 172.55.55.102/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:sxu; \
              sudo ip addr add $TARGET_IP_S1U brd + dev $TARGET_IFACE label $TARGET_IFACE:s1u; \
              LIST=\$(grep -ris lte /etc/iproute2/rt_tables); \
              if [ -z "$LIST" ]; then echo '200 lte' | sudo tee --append /etc/iproute2/rt_tables; else echo "lte table has already created"; fi; \
              sudo ip r add default via $TARGET_IP_SGI dev $TARGET_SGI_IFACE table lte; \
              sudo ip rule add from 12.0.0.0/8 table lte; \
              sudo -E spgwu -c $PREFIX/spgw_u.conf 2>&1 | tee ~/logs/spgwu.log' C-m $TARGET_PASSWORD C-m"

}

sessionAttach(){
    ssh -t  "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
    "tmux select-pane -t $TARGET_USER-OAI:0.0 && \
     tmux -2 attach-session -t $TARGET_USER-OAI"
 }

sessionStop(){
    ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
        "tmux send-keys -t $TARGET_USER-OAI:1.0 \
             'ps -ef | grep -e \"oai_hss\" | grep -v grep | awk '\''{print \$2}'\'' | xargs -r sudo kill -9; \
             sudo ip addr del 172.16.1.102/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:m11; \
             sudo ip addr del $TARGET_IP_S10 brd + dev $TARGET_IFACE label $TARGET_IFACE:m10; \
             sudo ip addr del 172.55.55.101/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:sxc; \
             sudo ip addr del 172.58.58.102/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:s5c; \
             sudo ip addr del 172.58.58.101/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:p5c; \
             sudo ip addr del 172.16.1.104/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:s11; \
             sudo ip addr del 172.55.55.102/24 brd + dev $TARGET_IFACE label $TARGET_IFACE:sxu; \
             sudo ip addr del $TARGET_IP_S1U brd + dev $TARGET_IFACE label $TARGET_IFACE:s1u' C-m $TARGET_PASSWORD C-m"
}

sessionKill(){
    ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
        "sleep 1; \
         tmux kill-session -t $TARGET_USER-OAI 2>/dev/null"
}

main(){
    if [[ $# != 6 ]]; then
        >&2 echo "Invalid args! ./oai-session.sh <remote_user> <remote_ip> <remote_port> <remote_password> <remote_s1c_interface> <remote_sgi_interface>"
        >&2 echo "e.g. ./oai-session.sh epc 127.0.0.1 2222 epc enp6s0 enp1s0"
        exit 1
    fi

    TARGET_USER=$1
    TARGET_IP=$2
    TARGET_PORT=$3
    TARGET_PASSWORD=$4
    TARGET_IFACE=$5
    TARGET_SGI_IFACE=$6

    TARGET_IP_S1U=192.168.15.18
    TARGET_IP_S10=192.168.15.19
    TARGET_IP_SGI=10.50.11.227
    
    sessionStart
    sessionAttach
    sessionStop
    sessionKill
    copyLogs
}

main "$@"
