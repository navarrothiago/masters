#!/bin/bash

#Cria a sessao tmux remota com os paineis:

sessionStart(){
ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
    "tmux kill-session -t $TARGET_USER-OAI 2>/dev/null; \
     set -- \$(stty size) && \
     tmux -2 new-session -d -s $TARGET_USER-OAI -x \$2 -y \$((\$1 - 1)) && \
     tmux split-window -t $TARGET_USER-OAI:0.0 -v && \
     tmux split-window -t $TARGET_USER-OAI:0.1 -v && \
     tmux split-window -t $TARGET_USER-OAI:0.2 -v && \
     tmux split-window -t $TARGET_USER-OAI:0.3 -v && \
     tmux select-layout even-vertical && \
     tmux resize-pane -t $TARGET_USER-OAI:0.0 -U 5 && \
     tmux resize-pane -t $TARGET_USER-OAI:0.1 -U 4 && \
     tmux resize-pane -t $TARGET_USER-OAI:0.2 -U 3 && \
     tmux split-window -t $TARGET_USER-OAI:0.0 -h && \
     tmux split-window -t $TARGET_USER-OAI:0.3 -h && \
     tmux split-window -t $TARGET_USER-OAI:0.4 -h && \
     tmux split-window -t $TARGET_USER-OAI:0.7 -v"
}

sessionAttach(){
    ssh -t  "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
    "tmux select-pane -t $TARGET_USER-OAI:0.4 && \
     tmux -2 attach-session -t $TARGET_USER-OAI"
 }

sessionStop(){
    ssh -t "$TARGET_USER"@"$TARGET_IP" -p "$TARGET_PORT" \
        "tmux send-keys -t $TARGET_USER-OAI:0.7 \
            'ps -ef | grep -e \"oai_hss | grep -v grep | awk '\''{print \$2}'\'' | xargs -r sudo kill -9' C-m '$TARGET_PASSWORD' C-m && \
         tmux send-keys -t $TARGET_USER-OAI:0.8 \
            'ps -ef | grep -e \"Package\" -e \"sca\" | grep -v grep | awk '\''{print \$2}'\'' | xargs -r sudo kill -9' C-m '$TARGET_PASSWORD' C-m && \
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
