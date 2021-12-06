#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./config.sh
. ./colors.sh
. ./environment.sh

#send a message
echo "Install PostgreSQL"

#generate a random password
password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64)

#install message
echo "Install PostgreSQL and create the database and users\n"

#postgres official repository

echo "deb http://apt.postgresql.org/pub/repos/apt/ $os_codename-pgdg main" > /etc/apt/sources.list.d/postgresql.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update && apt-get upgrade -y
#apt-get install -y sudo postgresql-12
apt-get install -y sudo postgresql-client-12 bison flex libreadline-dev

cd /usr/src
git clone -b bdr-pg/REL9_4_STABLE https://github.com/2ndQuadrant/bdr.git
cd bdr
./configure --build=aarch64-linux-gnu --prefix=/usr --includedir=/usr/include --mandir=/usr/share/man --infodir=/usr/share/info --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib/aarch64-linux-gnu --libexecdir=/usr/lib/aarch64-linux-gnu --with-openssl  --mandir=/usr/share/postgresql/9.4/man --docdir=/usr/share/doc/postgresql-doc-9.4 --sysconfdir=/etc/postgresql-common --datarootdir=/usr/share/ --datadir=/usr/share/postgresql/9.4 --bindir=/usr/lib/postgresql/9.4/bin --libdir=/usr/lib/aarch64-linux-gnu/ --libexecdir=/usr/lib/postgresql/ --includedir=/usr/include/postgresql/ --enable-nls --enable-integer-datetimes --enable-thread-safety --enable-tap-tests --disable-rpath --with-uuid=e2fs --with-gnu-ld --with-pgport=5432
make all
make install
cd contrib
make all
make install

cp /usr/lib/postgresql/9.4/bin/pg_config /usr/bin/pg_config

cd /usr/src
wget https://github.com/2ndQuadrant/bdr/archive/refs/tags/bdr-plugin/1.0.7.tar.gz
tar -zxvf 1.0.7.tar.gz
cd bdr-bdr-plugin-1.0.7/
./configure
make all
make install

pg_createcluster -d /var/lib/postgresql/9.4/main 9.4 main

cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/ssl-cert-snakeoil-postgres.key
chown postgres:postgres /etc/ssl/private/ssl-cert-snakeoil-postgres.key
chmod 600 /etc/ssl/private/ssl-cert-snakeoil-postgres.key

cp "$(dirname $0)/source/postgresql.service" /usr//lib/systemd/system/postgresql.service
cp "$(dirname $0)/source/postgresql@.service" /usr/lib/systemd/system/postgresql@.service
cp "$(dirname $0)/source/postgresql.conf" /etc/postgresql/9.4/main/postgresql.conf

systemctl daemon-reload

systemctl enable postgresql.service
systemctl enable postgresql@9.4-main.service


#add additional dependencies
apt install -y libpq-dev

#systemd
systemctl daemon-reload
systemctl restart postgresql

#init.d
#/usr/sbin/service postgresql restart

#install the database backup
#cp backup/fusionpbx-backup /etc/cron.daily
#cp backup/fusionpbx-maintenance /etc/cron.daily
#chmod 755 /etc/cron.daily/fusionpbx-backup
#chmod 755 /etc/cron.daily/fusionpbx-maintenance
#sed -i "s/zzz/$password/g" /etc/cron.daily/fusionpbx-backup
#sed -i "s/zzz/$password/g" /etc/cron.daily/fusionpbx-maintenance

#move to /tmp to prevent a red herring error when running sudo with psql
cwd=$(pwd)
cd /tmp

#add the databases, users and grant permissions to them
sudo -u postgres psql -c "CREATE DATABASE fusionpbx;";
sudo -u postgres psql -c "CREATE DATABASE freeswitch;";
sudo -u postgres psql -c "CREATE ROLE fusionpbx WITH SUPERUSER LOGIN PASSWORD '$password';"
sudo -u postgres psql -c "CREATE ROLE freeswitch WITH SUPERUSER LOGIN PASSWORD '$password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE fusionpbx to fusionpbx;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE freeswitch to fusionpbx;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE freeswitch to freeswitch;"
#ALTER USER fusionpbx WITH PASSWORD 'newpassword';
cd $cwd

#set the ip address
#server_address=$(hostname -I)
