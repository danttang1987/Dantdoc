#!/bin/bash

#Dir List
# mkdir -p /deploy/code/web-demo -p
# mkdir -p /deploy/config/web-demo/base
# mkdir -p /deploy/config/web-demo/other
# mkdir -p /deploy/tar
# mkdir -p /deploy/tmp
# mkdir -p /opt/webroot
# mkdir /webroot
# chown -R www:www /deploy
# chown -R www:www /opt/webroot
# chown -R www:www /webroot

#shell Env
NODE_LIST="192.168.237.211 192.168.237.212 192.168.237.213"
SHELL_DIR="/home/www"
SHELL_NAME="$0"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"
CDATA=$(date +%F)
CTIME=$(date +%H-%M-%S)
SSH_PORT=22

#code Env
PRO_NAME="web-daemon"
CODE_DIR="/deploy/code/web-daemon"
CONFIG_DIR="/deploy/config/${PRO_NAME}"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"
LOCK_FILE="/tmp/${SHELL_NAME}.lock"
PKG_NAME="${PRO_NAME}_${API_VAR}-${CDATA}-${CTIME}"
WEB_ROOT="/opt/webroot"
. /etc/init.d/functions

usage(){
        echo "usage $0 { deploy | rollback }"
        exit 1
}

shell_lock(){
        touch $LOCK_FILE
}

shell_unlock(){
        rm -rf $LOCK_FILE
}

writelog(){
        local LOGINFO=$1
        local IS_EXIT=$3
        local AETVAL=$2
        LDATA=$(date +%F)
        LTIME=$(date +%H-%M-%S)
        if [ $AETVAL -eq 0 ]
        then
                echo "${LDATA} : $LTIME : ${SHELL_NAME} : ${LOGINFO} : Success" >>$SHELL_LOG
                action  "${LDATA} : $LTIME : ${SHELL_NAME} : ${LOGINFO} " /bin/true
        else
                echo "${LDATA} : $LTIME : ${SHELL_NAME} : ${LOGINFO} : Fail" >>$SHELL_LOG
                action "${LDATA} : $LTIME : ${SHELL_NAME} : ${LOGINFO} "  /bin/false
                if [ $IS_EXIT -eq 1 ]
                then
                        shell_unlock
                        exit 5
                fi
        fi

}

urltest(){
        local IP=$1
        local IS_EXIT=$2
        curl -s --head http://$IP | grep -i "200 ok"
        local AETVAL=$?
        if [ $IS_EXIT -eq 1 ]
        then
                writelog "test $IP" $AETVAL 1
        else
                writelog "test $IP" $AETVAL 0
        fi
        return $AETVAL

}



code_get(){
        writelog "code_get" 0 0
        cd $CODE_DIR && echo "git pull"
        cp -r $CODE_DIR $TMP_DIR
		#API_VAR=`cd $CODE_DIR && git show | grep commit| cut -d ' ' -f 2 | sed -r 's/(......).*/\1/g'`
        API_VAR="123"
}

code_config(){
        /bin/cp -r ${CONFIG_DIR}/base/* ${TMP_DIR}/${PRO_NAME}
        PKG_NAME="${PRO_NAME}_${API_VAR}-${CDATA}-${CTIME}"
        cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}
        writelog code_config $? 1
}
code_build(){
        echo code_build
}

code_tar(){
        cd ${TMP_DIR} && tar czf ${PKG_NAME}.tar.gz ${PKG_NAME}
        writelog "Creat ${PKG_NAME}.tar.gz" $? 1
} 

code_scp(){
        for node in $NODE_LIST
        do
                scp -P $SSH_PORT ${TMP_DIR}/${PKG_NAME}.tar.gz $node:/opt/webroot
                writelog "code_scp $node" $? 1
        done

}

cluster_node_out(){
        echo cluster_node_out
}

code_deploy(){
        for node in $NODE_LIST
        do
                ssh -p $SSH_PORT $node "cd /opt/webroot && tar zxf ${PKG_NAME}.tar.gz"
                ssh -p $SSH_PORT $node "ls -l /webroot/ | grep -w web-daemon | cut -d '/' -f 4 > /opt/webroot/upversion.conf"
                ssh -p $SSH_PORT $node "rm -f /webroot/${PRO_NAME} && ln -s /opt/webroot/${PKG_NAME} /webroot/${PRO_NAME}"
                writelog "code_deploy $node" $? 0
                urltest $node 0
                if [ $? -ne 0 ]
                then
                        rollback_version $node
                fi

        done
}

config_diff(){
        echo config_diff
}

cluster_node_in(){
        echo cluster_node_in
}

rollback_version(){
        ROLLBACK_LIST=$1
        for rollnode in $ROLLBACK_LIST
        do
                if [ -z $2 ]
                then
                        ssh -p $SSH_PORT $rollnode "rm -f /webroot/${PRO_NAME} && ln -s /opt/webroot/`cat /opt/webroot/upversion.conf` /webroot/${PRO_NAME}"
                        writelog "rollback_up_version $rollnode" $? 1
                else
                        ssh -p $SSH_PORT $rollnode "rm -f /webroot/${PRO_NAME} && ln -s /opt/webroot/$2 /webroot/${PRO_NAME}"
                        writelog "rollback_up_version $rollnode" $? 1
                fi
                urltest $rollnode 1
        done
}

rollback(){
        i=1
        IFSTMP=$IFS
        IFS=$'\n'
        for line in `ls -t /opt/webroot/ | grep -v '.tar.gz'`
        do
                        PKG_NAMES[$i]=$line
                        ((i++))
        done
        IFS=$IFSTMP
        PS3="Please select rollback version of number(q:exit):"
        select id in ${PKG_NAMES[@]}
        do
                        itens="${#PKG_NAMES[@]}"
                        if [ "$REPLY" -le "$itens" ]
                        then
                                if [ $REPLY -eq 1 ]
                                then
                                        rollback_version "$NODE_LIST"
                                else
                                        rollback_version "$NODE_LIST" ${PKG_NAMES[$REPLY]}
                                fi
                        elif [[ "$REPLY" == "q" || "$REPLY" == "Q" ]]
                        then
                                shell_unlock
                                exit 0
                        else
                                echo "Please select rollback version of number"
                        fi
        done

}

main(){
        D_MODE=$1
        if [ -f $LOCK_FILE ]
        then
                echo "the deploy is running"
                exit 1
        fi
        case $D_MODE in
                deploy)
                        shell_lock;
                        code_get;
                        code_config;
                        code_tar;
                        code_scp;
                        cluster_node_out;
                        code_deploy;
                        config_diff;
                        cluster_node_in;
                        shell_unlock;
                        ;;
                rollback)
                        shell_lock;
                        rollback;
                        shell_unlock;
                        ;;
                *)
                        usage;
        esac
}

main $1