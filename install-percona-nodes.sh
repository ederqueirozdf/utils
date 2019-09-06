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
PASSSSH=/usr/bin/sshpass

COPY=/usr/bin/ssh-copy-id

SCRIPTNODE2=install-percona2.sh
SCRIPTNODE3=install-percona3.sh


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
        echo "REALIZANDO COPIA SSH PARA O NODE2 - $NODE2"
        $PASSSSH -p $PASSWDNODES $COPY $USERNODES@$NODE2
echo ""
        echo "REALIZANDO COPIA SSH PARA O NODE3 - $NODE3"
        $PASSSSH -p $PASSWDNODES $COPY $USERNODES@$NODE3
sleep 5
	echo "+CHAVES SSH"

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
        echo "- DISABLE FIREWALL -"
        echo "--------------------"
	systemctl stop firewalld
	systemctl disable firewalld
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
	yum install Percona-XtraDB-Cluster-full-56 -y
   	 
         INICIAPERCONA
}


INICIAPERCONA(){
	
        echo "-------------------"
        echo "- INICIA PERCONA -"
        echo "-------------------"
	systemctl start mysql
	systemctl enable mysql
	echo " +++ Inicializando PERCONA ..."	
	
sleep 10
	echo " Aguarde ..."
	VALIDAPERCONA
}


VALIDAPERCONA(){
	system restart mysql
        echo "--------------------------"
        echo "- VALIDA SERVICO PERCONA -"
        echo "--------------------------"

	systemctl status mysql
	echo $?
	  if [ $? -eq 0 ]; then
	echo "+MYSQL IS RUNNING"
	FUNCTIONSPERCONA
	else
	 echo "-MYSQL IS ERROR"
	EXITPERCONA
	 fi
	
	
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
	echo "- INSTALAÇÃO CANCELADA"
	exit
}


CONFIGURANODE1(){

        echo "------------------------------"
        echo "-STOP PERCONA - $NODE1 "
        echo "------------------------------"
        systemctl stop mysql

#REMOVE LINHA STRING WSREP
	sed -i '/wsrep_cluster_address/d' $MYCNF
	sed -i '/wsrep_provider/d' $MYCNF
	sed -i '/wsrep_cluster_name/d' $MYCNF
	sed -i '/wsrep_node_name/d' $MYCNF
#FIM REMOVE WSREP

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
	systemctl start mysql
	VERIFYREPLICATION
}


CONFIGURANODE2(){

        echo "---------------------------"
        echo "- INSTALL PKGS $NODE2 - "
        echo "---------------------------"

        ssh $USERNODES@$NODE2 'yum install rsync lsof wget nmap perl-DBI perl-tests.x86_64 perl-Env.noarch perl-DBD-MySQL socat sshpass.x86_64 -y'

echo ""
        echo "---------------------------"
        echo "- DISABLE SELINUX $NODE2 -"
        echo "---------------------------"

        ssh $USERNODES@$NODE2 setenforce 0
        ssh $USERNODES@$NODE2 sed -i "s/enforcing/permissive/g" $SELINUX

        echo "-----------------------------"
        echo "- DISABLE FIREWALL - $NODE2  "
        echo "-----------------------------"

        ssh $USERNODES@$NODE2 systemctl stop firewalld
        ssh $USERNODES@$NODE2 systemctl disable firewalld

        echo "---------------------------------------------"
        echo "- CONFIGURE REPOSITORIO PERCONA - $NODE2"
        echo "---------------------------------------------"

        ssh $USERNODES@$NODE2 wget $PERC56$PERCVERSION
        ssh $USERNODES@$NODE2 tar -xvf $PERCVERSION

        echo "-----------------------------"
        echo "- INSTALL PERCONA - $NODE2 "
        echo "-----------------------------"
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-garbd-3-3.34-1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-client-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-devel-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-56-debuginfo-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-test-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-galera-3-debuginfo-3.34-1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-galera-3-3.34-1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 yum remove mariadb-libs -y
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-shared-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 yum install http://repo.percona.com/yum/percona-release-1.0-3.noarch.rpm -y
        ssh $USERNODES@$NODE2 yum install percona-xtrabackup perl-DBD-MySQL.x86_64 -y
        ssh $USERNODES@$NODE2 rpm -ivh Percona-XtraDB-Cluster-server-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE2 yum install Percona-XtraDB-Cluster-full-56 -y


        echo "----------------------------"
        echo "- INICIA PERCONA - $NODE2   "
        echo "----------------------------"
        ssh $USERNODES@$NODE2 systemctl start mysql
        ssh $USERNODES@$NODE2 systemctl enable mysql
        ssh $USERNODES@$NODE2 echo " +++ Inicializando PERCONA $NODE2..."
        ssh $USERNODES@$NODE2 sleep 5

        echo "-------------------------------------"
        echo "- VALIDA SERVICO PERCONA - $NODE2 "
        echo "-------------------------------------"

        ssh $USERNODES@$NODE2 'systemctl status mysql'
        ssh $USERNODES@$NODE2 'echo $?'
        ssh $USERNODES@$NODE2 'if [ $? -eq 0 ]; then'
        ssh $USERNODES@$NODE2 'echo "+MYSQL IS RUNNING"'
        ssh $USERNODES@$NODE2 'else'
        ssh $USERNODES@$NODE2 'echo "-MYSQL IS ERROR"'
        ssh $USERNODES@$NODE2 'exit'
        ssh $USERNODES@$NODE2 'fi'

        echo "----------------------------------"
        echo "-FUNCTIONS PERCONA - $NODE2"
        echo "----------------------------------"
	ssh $USERNODES@$NODE2 'systemctl restart mysql'
	ssh $USERNODES@$NODE2 'sleep 5'
        ssh $USERNODES@$NODE2 'mysql -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"'
        ssh $USERNODES@$NODE2 'mysql -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"'
        ssh $USERNODES@$NODE2 'mysql -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"'
        echo "-------------------------------------------"
        echo "+CRIANDO USUÁRIO DE SERVIÇO - $NODE2 "
        echo "-------------------------------------------"
        ssh $USERNODES@$NODE2 'mysql -e "CREATE USER '$UMYSQL'@'localhost' IDENTIFIED BY '$PWDMYSQL';"'
        ssh $USERNODES@$NODE2 'mysql -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '$UMYSQL'@'localhost';"'
        ssh $USERNODES@$NODE2 'mysql -e "FLUSH PRIVILEGES;"'

        echo ""
        echo " + CONFIG FILE"
        echo ""

        echo "------------------------------"
        echo "-STOP PERCONA - $NODE2 "
        echo "------------------------------"
        ssh $USERNODES@$NODE2 'systemctl stop mysql'

#REMOVE LINHA STRING WSREP
        ssh $USERNODES@$NODE2 'sed -i "/wsrep_cluster_address/d" '$MYCNF' '
        ssh $USERNODES@$NODE2 'sed -i "/wsrep_provider/d" '$MYCNF' '
        ssh $USERNODES@$NODE2 'sed -i "/wsrep_cluster_name/d" '$MYCNF' '
        ssh $USERNODES@$NODE2 'sed -i "/wsrep_node_name/d" '$MYCNF' '
#
        ssh $USERNODES@$NODE2 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "##########################" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "# ADD BY SCRIPT - $DATA" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "##########################" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo " CONFIGURANDO NODE2 - $NODE2"'
        ssh $USERNODES@$NODE2 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "wsrep_provider=/usr/lib64/galera3/libgalera_smm.so" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "wsrep_cluster_name=pxc-cluster" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "wsrep_cluster_address=gcomm://'$NODE1','$NODE2','$NODE3'" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "wsrep_node_name=pxc2" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "wsrep_node_address='$NODE2'" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "wsrep_sst_method=xtrabackup-v2" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "wsrep_sst_auth='$UMYSQL':'$PWDMYSQL'" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "pxc_strict_mode=ENFORCING" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "binlog_format=ROW" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "default_storage_engine=InnoDB" >> '$MYCNF' '
        ssh $USERNODES@$NODE2 'echo "innodb_autoinc_lock_mode=2" >> '$MYCNF''
        echo "------------------------------"
        echo "+INICIA PERCONA - $NODE2 "
        echo "------------------------------"
	ssh $USERNODES@$NODE2 'systemctl start mysql'
        REPNODE2
}

REPNODE2(){



        echo "--------------------------"
        echo "  Criando TABELA $NODE2 "
        echo "--------------------------"
        ssh $USERNODES@$NODE2 'mysql -e "USE percona"'
        ssh $USERNODES@$NODE2 'mysql -e "INSERT INTO percona.example VALUES (1, 'percona1');"'

}

CONFIGURANODE3(){

        echo "---------------------------"
        echo "- INSTALL PKGS $NODE3 - "
        echo "---------------------------"

	ssh $USERNODES@$NODE3 'yum install rsync lsof wget nmap perl-DBI perl-tests.x86_64 perl-Env.noarch perl-DBD-MySQL socat sshpass.x86_64 -y'

echo ""
        echo "---------------------------"
        echo "- DISABLE SELINUX $NODE3 -"
        echo "---------------------------"

	ssh $USERNODES@$NODE3 setenforce 0
	ssh $USERNODES@$NODE3 sed -i "s/enforcing/permissive/g" $SELINUX

        echo "-----------------------------"
        echo "- DISABLE FIREWALL - $NODE3  "
        echo "-----------------------------"

	ssh $USERNODES@$NODE3 systemctl stop firewalld
        ssh $USERNODES@$NODE3 systemctl disable firewalld

        echo "---------------------------------------------"
        echo "- CONFIGURE REPOSITORIO PERCONA - $NODE3"
        echo "---------------------------------------------"

        ssh $USERNODES@$NODE3 wget $PERC56$PERCVERSION
        ssh $USERNODES@$NODE3 tar -xvf $PERCVERSION

        echo "-----------------------------"
        echo "- INSTALL PERCONA - $NODE3 "
        echo "-----------------------------"

	ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-garbd-3-3.34-1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-client-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-devel-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-56-debuginfo-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-test-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-galera-3-debuginfo-3.34-1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-galera-3-3.34-1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 yum remove mariadb-libs -y
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-shared-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 yum install http://repo.percona.com/yum/percona-release-1.0-3.noarch.rpm -y
        ssh $USERNODES@$NODE3 yum install percona-xtrabackup perl-DBD-MySQL.x86_64 -y
        ssh $USERNODES@$NODE3 rpm -ivh Percona-XtraDB-Cluster-server-56-5.6.44-28.34.1.el7.x86_64.rpm
        ssh $USERNODES@$NODE3 yum install Percona-XtraDB-Cluster-full-56 -y


        echo "----------------------------"
        echo "- INICIA PERCONA - $NODE3   "
        echo "----------------------------"
	ssh $USERNODES@$NODE3 systemctl start mysql
        ssh $USERNODES@$NODE3 systemctl enable mysql
        ssh $USERNODES@$NODE3 echo " +++ Inicializando PERCONA $NODE3..."
	ssh $USERNODES@$NODE3 sleep 5

        echo "-------------------------------------"
        echo "- VALIDA SERVICO PERCONA - $NODE3 "
        echo "-------------------------------------"
	ssh $USERNODES@$NODE3 'systemctl restart mysql'
	ssh $USERNODES@$NODE3 'sleep 5'
        ssh $USERNODES@$NODE3 'systemctl status mysql'
        ssh $USERNODES@$NODE3 'echo $?'
        ssh $USERNODES@$NODE3 'if [ $? -eq 0 ]; then'
        ssh $USERNODES@$NODE3 'echo "+MYSQL IS RUNNING"'
        ssh $USERNODES@$NODE3 'else'
	ssh $USERNODES@$NODE3 'echo "-MYSQL IS ERROR"'
	ssh $USERNODES@$NODE3 'exit'
	ssh $USERNODES@$NODE3 'fi'

        echo "----------------------------------"
        echo "-FUNCTIONS PERCONA - $NODE3"
        echo "----------------------------------"
	ssh $USERNODES@$NODE3 ' mysql -e '"CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"' '
        ssh $USERNODES@$NODE3 ' mysql -e '"CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"' '
        ssh $USERNODES@$NODE3 ' mysql -e '"CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"' '

        echo "-------------------------------------------"
        echo "+CRIANDO USUÁRIO DE SERVIÇO - $NODE3 "
        echo "-------------------------------------------"
        ssh $USERNODES@$NODE3 ' mysql -e '"CREATE USER '$UMYSQL'@'localhost' IDENTIFIED BY '$PWDMYSQL';"' '
        ssh $USERNODES@$NODE3 ' mysql -e '"GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '$UMYSQL'@'localhost';"' '
        ssh $USERNODES@$NODE3 ' mysql -e '"FLUSH PRIVILEGES;"' '

	echo ""
	echo " + CONFIG FILE"
	echo ""

        echo "------------------------------"
        echo "-STOP PERCONA - $NODE3 "
        echo "------------------------------"
	ssh $USERNODES@$NODE3 'systemctl stop mysql'

#REMOVE LINHA STRING WSREP
        ssh $USERNODES@$NODE3 'sed -i '/wsrep_cluster_address/d' '$MYCNF' '
        ssh $USERNODES@$NODE3 'sed -i '/wsrep_provider/d' '$MYCNF' '
        ssh $USERNODES@$NODE3 'sed -i '/wsrep_cluster_name/d' '$MYCNF' '
        ssh $USERNODES@$NODE3 'sed -i '/wsrep_node_name/d' '$MYCNF' '
#
	ssh $USERNODES@$NODE3 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "##########################" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "# ADD BY SCRIPT - $DATA" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "##########################" >> '$MYCNF' '
	ssh $USERNODES@$NODE3 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo " CONFIGURANDO NODE3 - $NODE3"'
	ssh $USERNODES@$NODE3 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "wsrep_provider=/usr/lib64/galera3/libgalera_smm.so" >> '$MYCNF' '
	ssh $USERNODES@$NODE3 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "wsrep_cluster_name=pxc-cluster" >> '$MYCNF' '
	ssh $USERNODES@$NODE3 'echo "wsrep_cluster_address=gcomm://'$NODE1','$NODE2','$NODE3'" >> '$MYCNF' '
	ssh $USERNODES@$NODE3 'echo "wsrep_node_name=pxc2" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "wsrep_node_address='$NODE3'" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "wsrep_sst_method=xtrabackup-v2" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "wsrep_sst_auth='$UMYSQL':'$PWDMYSQL'" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "pxc_strict_mode=ENFORCING" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "binlog_format=ROW" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "default_storage_engine=InnoDB" >> '$MYCNF' '
        ssh $USERNODES@$NODE3 'echo "innodb_autoinc_lock_mode=2" >> '$MYCNF' '

        echo "------------------------------"
        echo "+INICIA PERCONA - $NODE3 "
        echo "------------------------------"
	ssh $USERNODES@$NODE3 'systemctl start mysql'
	REPNODE3
}

REPNODE3(){



        echo "--------------------------"
        echo "  SELECT TABELA $NODE3 "
        echo "--------------------------"
        ssh $USERNODES@$NODE3 'mysql -e "USE percona"'
        ssh $USERNODES@$NODE3 'mysql -e "SELECT * FROM percona.example;"'

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
	echo "--------------------------"
	echo "  Criando DATABASE $NODE1 "
	echo "--------------------------"
echo ""
	mysql -e "CREATE DATABASE percona;"
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
          if [ $? -eq 0 ]; then
        echo "+MYSQL IS RUNNING"
        else
         echo "-MYSQL IS ERROR"
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
CONFIGURANODE1
CONFIGURANODE2
CONFIGURANODE3
MONITOR
