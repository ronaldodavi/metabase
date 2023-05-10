#!/bin/bash
# Para Centos 7
# Metabase, Openjdk 1.8, Postgresql-15, Nginx como proxy
# Banco: metabseappdb
# 
# Por Ronaldo davi
# 27/04/2023
# Versão 1.0.0.6

# Desativando selinux
setenforce 0
wait
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
setsebool -P httpd_can_network_connect_db 1
systemctl stop firewalld
systemctl disable firewalld
wait
yum -y update
wait 
yum install -y epel-release yum-utils
wait
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
wait
sleep 5
sudo yum install -y postgresql15-server
wait
sleep 5
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
wait
sudo systemctl enable postgresql-15
sudo systemctl start postgresql-15
wait
sudo -u postgres createdb metabaseappdb
wait
rm -rf /var/lib/pgsql/15/data/pg_hba.conf
echo "
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
host    all             all             0.0.0.0/0               trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
" >> /var/lib/pgsql/15/data/pg_hba.conf

wait
systemctl restart postgresql-15
wait
yum -y install java-1.8.0-openjdk vim wget epel-release
wait
readlink -f /usr/bin/java | sed "s:/jre/bin/java::"
wait
echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.362.b08-1.el7_9.x86_64" | tee -a /etc/profile
wait
source /etc/profile
wait
wget http://downloads.metabase.com/v0.29.3/metabase.jar
wait
adduser --home-dir /var/metabase --comment="Metabase User" --shell /sbin/nologin metabase
wait
mv metabase.jar /var/metabase
wait
chown metabase:metabase -R /var/metabase
wait
#touch /var/metabase/metabase.env
echo "
if $programname == 'metabase' then /var/log/metabase.log
& stop
" >> /etc/rsyslog.d/metabase.conf
#sudo chown syslog:adm /var/log/metabase.log
wait
sudo systemctl restart rsyslog.service

echo "
MB_PASSWORD_COMPLEXITY=normal
MB_DB_TYPE=postgres
MB_DB_DBNAME=metabaseappdb
MB_DB_PORT=5432
MB_DB_USER=postgres
MB_DB_PASS=q1w2e3r4
MB_DB_HOST=localhost
MB_EMOJI_IN_LOGS=true
# any other env vars you want available to Metabase
" >> /etc/default/metabase
wait
echo "[Unit]
Description=Metabase server
After=syslog.target
After=network.target

[Service]
EnvironmentFile=/etc/default/metabase
User=metabase
Group=metabase
Type=simple
ExecStart=/usr/bin/java -jar /var/metabase/metabase.jar
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=metabase

[Install]
WantedBy=multi-user.target " >> /etc/systemd/system/metabase.service

wait
systemctl enable metabase
systemctl start metabase
systemctl status metabase
systemctl status postgresql-15

yum -y install nginx

systemctl start nginx

systemctl enable nginx

echo " server {
    listen 80;
    server_name metabase.example.com; 
    access_log  /var/log/nginx/metabase.access.log;
	error_log  /var/log/nginx/metabase.error.log;
    
location / {
    proxy_pass			http://localhost:3000;        
    } 
} " >> /etc/nginx/conf.d/metabase.conf

systemctl restart nginx
systemctl status metabase
