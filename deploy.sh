#!/bin/bash
# Node_List
NODE_LIST="192.168.56.15 192.168.56.16"
ROLLBACK_LIST="192.168.56.15 192.168.56.16"

# Date/Time veriables
LOG_DATE=`date "+%Y-%m-%d"`
LOG_TIME=`date "+%H-%M-%S"`

CDATE=$(date "+%Y-%m-%d")
CTIME=$(date "+%H-%M-%S")

# Shell Env
SHELL_NAME="deploy.sh"
SHELL_DIR="/server/scripts/"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"

# Code ENV
PRO_NAME="web-demo"
CODE_DIR="/deploy/code/web-demo"
CONFIG_DIR="/deploy/config/web-demo"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"
LOCK_FILE="/var/run/deploy.lock"

usage(){
	echo $"Usage: $0  deploy | rollback  [ list | version ]"

}

writelog(){
	LOGINFO=$1
	echo "${CDATE} ${CTIME}: ${SEELL_NAME} : ${LOGINFO}" >> ${SHELL_LOG}

}

shell_lock(){
	touch ${LOCK_FILE}

}

shell_unlock(){
	rm -r ${LOCK_FILE}

}

code_get(){
	writelog "code_get";
	cd $CODE_DIR && git pull
	cp -r ${CODE_DIR} ${TMP_DIR}/
	API_VERL=$(git show |grep commit | cut -d ' ' -f2)
	API_VER=$(echo ${API_VERL:0:6})	
}

code_build(){
	echo code_build

}

code_config(){
	writelog "code_config"	
	/bin/cp -r ${CONFIG_DIR}/base/* ${TMP_DIR}/"${PRO_NAME}"
	PKG_NAME="${PRO_NAME}"_"${API_VER}"_"${CDATE}"-"${CTIME}"
	cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}
}

code_tar(){
	writelog "code_tar"
	cd ${TMP_DIR} && /usr/bin/tar zcf ${PKG_NAME}.tar.gz ${PKG_NAME} 
	writelog "${PKG_NAME}.tar.gz"

}

code_scp(){
	writelog "code_scp"
	for node in $NODE_LIST;do
		scp ${TMP_DIR}/${PKG_NAME}.tar.gz $node:/data/webroot/
	done

}

cluster_node_remove(){
	writelog cluseter_node_remove


}

code_deploy(){
	writelog code_deploy
       for node in $NODE_LIST;do
		ssh $node "cd /data/webroot && tar zxf ${PKG_NAME}.tar.gz"
		ssh $node "rm -rf /application/nginx/html/webroot/web-demo && ln -s /data/webroot/${PKG_NAME} /application/nginx/html/webroot/web-demo"
        	
done
                scp ${CONFIG_DIR}/other/192.168.56.15.crontab.xml 192.168.56.15:/application/nginx/html/webroot/web-demo/crontab.xml
}

cluster_node_in(){
	echo cluster_node_in


}

rollback_fun(){
	for node in $ROLLBACK_LIST;do
        ssh $node "rm -rf /application/nginx/html/webroot/web-demo && ln -s /data/webroot/$1 /application/nginx/html/webroot/web-demo"
        done


}

rollback(){
if [ -z $1 ];then
	shell_unlock;
	echo "Please input rollback version" && exit;
fi
	case $1 in 
	      list)
		       ssh 192.168.56.15 "ls -l /data/webroot/*.tar.gz"
		;;
	*)
		rollback_fun $1
	esac	

}

main(){	
    if [ -f $LOCK_FILE ];then
           echo "Deploy is running"  && exit;
  fi
	DEPLOY_METHOD=$1
	ROLLBACK_VER=$2
	case $DEPLOY_METHOD in 
	   deploy)
		shell_lock;
		code_get;
		code_build;
		code_config;
		code_tar;
		code_scp;
		cluster_node_remove;
		code_deploy;
		cluster_node_in;
		shell_unlock;
		;;
	   rollback)
		shell_lock;
		rollback $ROLLBACK_VER;
		shell_unlock
		;;
	*)
		usage; 
     esac

}
main $1 $2  
