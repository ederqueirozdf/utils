#!/bin/bash

#------------------------------------------------------------------#
# Version: 1.0
# Date of create: 22/08/2019
# Create by: Eder Queiroz - ederbritodf@gmail.com
#------------------------------------------------------------------#

#######################
## VARIAVEIS GLOBAIS ##
#######################


SELINUX=/etc/selinux/config
#REPOPERCONA=https://repo.percona.com/yum/percona-release-latest.noarch.rpm

#PERCONA56
#https://www.percona.com/downloads/Percona-XtraDB-Cluster-56/LATEST/

REPOPERCONA=https://www.percona.com/downloads/Percona-XtraDB-Cluster-56/Percona-XtraDB-Cluster-5.6.44-28.34/binary/redhat/7/x86_64/$REPOVERSION
REPOVERSION=Percona-XtraDB-Cluster-server-56-5.6.44-28.34.1.el7.x86_64.rpm
PERC56=https://www.percona.com/downloads/Percona-XtraDB-Cluster-56/Percona-XtraDB-Cluster-5.6.44-28.34/binary/redhat/7/x86_64/
PERCVERSION=Percona-XtraDB-Cluster-5.6.44-28.34-r104-el7-x86_64-bundle.tar

MYCNF=/etc/my.cnf
DATA=`date +%d-%m-%Y-%H:%M:%S`
UMYSQL=sstuser
PWDMYSQL=P3rC0N4BacK4p

#######################
### FIM VARIAVEIS #####
#######################

#######################
#######################
#######################


#
#Configure SELINUX
#
#The SELinux security module can constrain access to data for Percona XtraDB Cluster. The best solution is to change the mode from enforcing to permissive by running the following command:

HOSTS(){
echo ""
	echo "--------------------------------------------"
	echo "INFORME O IP DOS HOSTS QUE COMPOEM O CLUSTER"
	echo "--------------------------------------------"
	echo "INFORME O IP DO NODE1"
	read NODE1
	echo "+IP ATRIBUIDO: $NODE1"
echo ""
	echo "INFORME O IP DO NODE2"
	read NODE2
        echo "+IP ATRIBUIDO: $NODE2"
echo ""
	echo "INFORME O IP DO NODE3"
	read NODE3
        echo "+IP ATRIBUIDO: $NODE3"
echo ""
	echo "|-----------|-----------|"
	echo "| HOSTS:    | IP:       |"
	echo "|-----------|-----------|"
	echo "| NODE1     | $NODE1|"
	echo "|-----------|-----------|"
	echo "| NODE2     | $NODE2|"
	echo "|-----------|-----------|"
	echo "| NODE3     | $NODE3|"
	echo "|-----------|-----------|"
echo ""

}

USERHOSTS(){
echo -n "INFORME O USUÁRIO DE CONEXAO REMOTA AOS NODES: "
read USERNODES
echo -n "INFORME A SENHA DO USUÁRIO $USERNODES: "
read -s PASSWDNODES
export -p PASSWDNODES
echo ""
}


CHAVESSH(){

echo ""
        echo "--------------------------------------------"
        echo "CONFIGURANDO CHAVE SSH RSA"
        echo "--------------------------------------------"
	ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
echo ""
	echo "REALIZANDO COPIA SSH PARA O NODE1 - $NODE1"
#	sshpass -p $PASSWDNODES scp ~/.ssh/id_rsa.pub $USERNODES@$NODE1:/root/.ssh/
	sshpass -p $PASSWDNODES ssh-copy-id $USERNODES@$NODE1
echo ""
        echo "REALIZANDO COPIA SSH PARA O NODE2 - $NODE2"
        sshpass -p $PASSWDNODES ssh-copy-id $USERNODES@$NODE2
echo ""
        echo "REALIZANDO COPIA SSH PARA O NODE1 - $NODE3"
        sshpass -p $PASSWDNODES ssh-copy-id $USERNODES@$NODE3

}


PREREQS(){
echo ""
        echo "--------------------"
        echo "- UPDATE LINUX -"
        echo "--------------------"
        yum update -y
echo ""
        echo "--------------------"
        echo "- INSTALL PACKAGES -"
        echo "--------------------"
	yum install rsync lsof wget nmap perl-DBI perl-tests.x86_64 perl-Env.noarch perl-DBD-MySQL socat sshpass.x86_64 -y
echo ""
}

SELINUX(){
        echo "--------------------"
        echo "- DISABLE SELINUX -"
        echo "--------------------"
        setenforce 0
        sed -i "s/enforcing/permissive/g" $SELINUX
}

FIREWALL(){

        echo "--------------------"
        echo "- DISABLE SELINUX -"
        echo "--------------------"
        setenforce 0
        sed -i "s/enforcing/permissive/g" $SELINUX
}

RPMPERCONA(){

        echo "---------------------------------"
        echo "- CONFIGURE REPOSITORIO PERCONA -"
        echo "---------------------------------"

	wget $PERC56$PERCVERSION
	tar -xvf $PERCVERSION

}



INSTALLPERCONA(){

        echo "-------------------"
        echo "- INSTALL PERCONA -"
        echo "-------------------"
	rpm -ivh Percona-XtraDB-Cluster-garbd-3-3.34-1.el7.x86_64.rpm
	rpm -ivh Percona-XtraDB-Cluster-client-56-5.6.44-28.34.1.el7.x86_64.rpm
	rpm -ivh Percona-XtraDB-Cluster-devel-56-5.6.44-28.34.1.el7.x86_64.rpm
	rpm -ivh Percona-XtraDB-Cluster-56-debuginfo-5.6.44-28.34.1.el7.x86_64.rpm
	rpm -ivh Percona-XtraDB-Cluster-test-56-5.6.44-28.34.1.el7.x86_64.rpm 
	rpm -ivh Percona-XtraDB-Cluster-galera-3-debuginfo-3.34-1.el7.x86_64.rpm 
	rpm -ivh Percona-XtraDB-Cluster-galera-3-3.34-1.el7.x86_64.rpm
	yum remove mariadb-libs -y
	rpm -ivh Percona-XtraDB-Cluster-shared-56-5.6.44-28.34.1.el7.x86_64.rpm
	yum install http://repo.percona.com/yum/percona-release-1.0-3.noarch.rpm -y
	yum install percona-xtrabackup perl-DBD-MySQL.x86_64 -y
	rpm -ivh Percona-XtraDB-Cluster-server-56-5.6.44-28.34.1.el7.x86_64.rpm
	yum install Percona-XtraDB-Cluster-full-56
   	 
         INICIAPERCONA
}


INICIAPERCONA(){
	
        echo "-------------------"
        echo "- INICIA PERCONA -"
        echo "-------------------"
	systemctl start mysql
	systemctl enable mysql
	
	VALIDAPERCONA
}


VALIDAPERCONA(){

        echo "--------------------------"
        echo "- VALIDA SERVICO PERCONA -"
        echo "--------------------------"

	systemctl status mysql
	echo $?
echo ""
	  if [$? == 0]; then
	echo "+MYSQL IS RUNNING"
echo ""	 
	FUNCTIONPERCONA
	else
echo ""
	 echo "-MYSQL IS ERROR"
echo ""
	 fi
	
	EXITPERCONA
	
}

FUNCTIONSPERCONA(){
        echo "-------------------"
        echo "-FUNCTIONS PERCONA-"
        echo "-------------------"
	mysql -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
	mysql -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
	mysql -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"

	USRPERCONA
}

USRPERCONA (){

#State Snapshot Transfer is the full copy of data from one node to another. 
#It’s used when a new node joins the cluster, it has to transfer data from existing node.
echo ""
	echo "---------------------------"
	echo "+CRIANDO USUÁRIO DE SERVIÇO"
        echo "---------------------------"
echo ""
	mysql -e "CREATE USER '$UMYSQL'@'localhost' IDENTIFIED BY '$PWDMYSQL';"
	mysql -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '$UMYSQL'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
echo ""
}

EXITPERCONA(){
	
echo ""
	echo "------------------------------"
	echo "FALHA NA INSTALAÇÃO DO PERCONA"
	echo "------------------------------"
}


CONFIGNODE1(){
	 STOPPERCONA
echo "" >> $MYCNF
echo "##########################" >> $MYCNF
echo "# ADD BY SCRIPT - $DATA" >> $MYCNF
echo "##########################" >> $MYCNF
echo ""
	echo " CONFIGURANDO NODE1 - $NODE1" 
echo "" >> $MYCNF
	echo "wsrep_provider=/usr/lib64/galera3/libgalera_smm.so" >> $MYCNF
echo "" >> $MYCNF
	echo "wsrep_cluster_name=pxc-cluster" >> $MYCNF
	echo "wsrep_cluster_address=gcomm://$NODE1,$NODE2,$NODE3" >> $MYCNF
	echo "wsrep_node_name=pxc1" >> $MYCNF
	echo "wsrep_node_address=$NODE1" >> $MYCNF
	echo "" >> $MYCNF
	echo "wsrep_sst_method=xtrabackup-v2" >> $MYCNF
	echo "wsrep_sst_auth=$UMYSQL:$PWDMYSQL" >> $MYCNF
	echo "" >> $MYCNF
	echo "pxc_strict_mode=ENFORCING" >> $MYCNF
	echo "" >> $MYCNF
	echo "binlog_format=ROW" >> $MYCNF
	echo "default_storage_engine=InnoDB" >> $MYCNF
	echo "innodb_autoinc_lock_mode=2" >> $MYCNF
}

CONFIGNODE2(){
	ssh $USERNODES@$NODE2
	PREREQS
	SELINUX
	FIREWALL
	RPMPERCONA
	INSTALLPERCONA
	STOPPERCONA
echo "" >> $MYCNF
	echo "##########################" >> $MYCNF
	echo "# ADD BY SCRIPT - $DATA" >> $MYCNF
	echo "##########################" >> $MYCNF
echo "" >> $MYCNF
	echo " CONFIGURANDO NODE2 - $NODE2"
echo "" >> $MYCNF
        echo "wsrep_provider=/usr/lib64/galera3/libgalera_smm.so" >> $MYCNF
echo "" >> $MYCNF
        echo "wsrep_cluster_name=pxc-cluster" >> $MYCNF
        echo "wsrep_cluster_address=gcomm://$NODE1,$NODE2,$NODE3" >> $MYCNF
	echo "wsrep_node_name=pxc2" >> $MYCNF
	echo "wsrep_node_address=$NODE2" >> $MYCNF
        echo "" >> $MYCNF
        echo "wsrep_sst_method=xtrabackup-v2" >> $MYCNF
        echo "wsrep_sst_auth=$UMYSQL:$PWDMYSQL" >> $MYCNF
        echo "" >> $MYCNF
        echo "pxc_strict_mode=ENFORCING" >> $MYCNF
        echo "" >> $MYCNF
        echo "binlog_format=ROW" >> $MYCNF
        echo "default_storage_engine=InnoDB" >> $MYCNF
        echo "innodb_autoinc_lock_mode=2" >> $MYCNF

	INICIAPERCONAHOST
}

CONFIGNODE3(){
echo ""
echo "ACESSANDO NODE3"
echo ""
        ssh $USERNODES@$NODE3
        PREREQS
        SELINUX
        FIREWALL
        RPMPERCONA
        INSTALLPERCONA
        STOPPERCONA

	STOPPERCONA
echo "" >> $MYCNF
        echo "##########################" >> $MYCNF
        echo "# ADD BY SCRIPT - $DATA" >> $MYCNF
        echo "##########################" >> $MYCNF
echo "" >> $MYCNF
        echo " CONFIGURANDO NODE3 - $NODE3" >> $MYCNF
echo "" >> $MYCNF
        echo "wsrep_provider=/usr/lib64/galera3/libgalera_smm.so" >> $MYCNF
echo "" >> $MYCNF
        echo "wsrep_cluster_name=pxc-cluster" >> $MYCNF
        echo "wsrep_cluster_address=gcomm://$NODE1,$NODE2,$NODE3" >> $MYCNF
        echo "wsrep_node_name=pxc2" >> $MYCNF
        echo "wsrep_node_address=$NODE3" >> $MYCNF
        echo "" >> $MYCNF
        echo "wsrep_sst_method=xtrabackup-v2" >> $MYCNF
        echo "wsrep_sst_auth=$UMYSQL:$PWDMYSQL" >> $MYCNF
        echo "" >> $MYCNF
        echo "pxc_strict_mode=ENFORCING" >> $MYCNF
        echo "" >> $MYCNF
        echo "binlog_format=ROW" >> $MYCNF
        echo "default_storage_engine=InnoDB" >> $MYCNF
        echo "innodb_autoinc_lock_mode=2" >> $MYCNF

	INICIAPERCONAHOST
}


STOPPERCONA(){
	echo "--------------"
	echo "-STOP PERCONA "
	echo "--------------"
	systemctl stop mysql
}

BOOTSTRAPPING(){

echo ""
	echo "--------------------"
	echo "+INICIANDO PERCONA BOOTSTRAPPING"
	echo "--------------------"
echo ""
	systemctl start mysql@bootstrap.service
echo ""
	echo "Para certificar-se que o cluster foi inicializado:"
echo ""
	mysql -e "show status like 'wsrep%';"
}

VERIFYREPLICATION(){

#Use the following procedure to verify replication by creating a new database on the second node
#creating a table for that database on the third node, and adding some records to the table on the first node.
echo ""
	echo "-----------------------------------"
	echo " INICIANDO VALIDAÇÃO DE REPLICAÇÃO "
	echo "-----------------------------------"
echo ""
	echo "--------------------------"
	echo "  Criando DATABASE NODE1 "
	echo "--------------------------"
echo ""
	mysql -e "CREATE DATABASE percona;"
}

REPNODE2(){

echo""
	echo "-------------------------"
	echo " ACESSANDO NODE2 "
	echo "-------------------------"
	ssh $USERNODES@$NODE2
echo ""
        echo "--------------------------"
        echo "  Criando TABELA NODE2 "
        echo "--------------------------"
echo ""

        mysql -e "USE percona"
        mysql -e "INSERT INTO percona.example VALUES (1, 'percona1');"
echo ""
	EXITHOST

}

REPNODE3(){

echo""
        echo "-------------------------"
        echo " ACESSANDO NODE3 "
        echo "-------------------------"
        ssh $USERNODES@$NODE3
echo ""

echo ""
        echo "--------------------------"
        echo "  EXECUTANDO SELECT NODE3 "
        echo "--------------------------"
echo ""
	mysql -e "SELECT * FROM percona.example;"

	EXITHOST
}

MONITOR(){
echo ""
	echo "----------------------"
	echo "+EXIBINDO SAÍDA MONITOR"
	echo "----------------------"
echo""
	mysql -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
}

EXITHOST(){
echo ""
	echo "LOGOUT HOST"
	exit
}

INICIAPERCONAHOST(){

        echo "-------------------"
        echo "- INICIA PERCONA  -"
        echo "-------------------"
        systemctl start mysql
        systemctl enable mysql

        VALIDAPERCONAHOST
}

VALIDAPERCONAHOST(){

        echo "--------------------------"
        echo "- VALIDA SERVICO PERCONA -"
        echo "--------------------------"

        systemctl status mysql
        echo $?
echo ""
          if [$? == 0]; then
        echo "+MYSQL IS RUNNING"
echo ""  
        else
echo ""
         echo "-MYSQL IS ERROR"
echo ""
         fi

        EXITPERCONA
	EXITHOST

}




HOSTS
USERHOSTS
PREREQS
SELINUX
FIREWALL
CHAVESSH
RPMPERCONA
INSTALLPERCONA
CONFIGNODE1
CONFIGNODE2
CONFIGNODE3
VERIFYREPLICATION
REPNODE2
REPNODE3
MONITOR
