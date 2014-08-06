#
### MAPSERVER WORKER ###
#


GISLAB_WORKER_IMAGE_ROOT=/opt/worker
GISLAB_WORKER_IMAGE_BASE=$GISLAB_WORKER_IMAGE_ROOT/base

rm -rf $GISLAB_WORKER_IMAGE_ROOT
mkdir -p $GISLAB_WORKER_IMAGE_ROOT $GISLAB_WORKER_IMAGE_BASE


GISLAB_WORKER_INSTALL_PACKAGES="
    apache2
    apache2-mpm-worker
    gdal-bin
    htop
    libapache2-mod-fastcgi
    libgdal1h
    mc
    nfs-common
    ntp
    python-gdal
    python-qgis
    qgis
    qgis-mapserver
    vim
"
GISLAB_WORKER_INSTALL_PACKAGES=$(echo $GISLAB_WORKER_INSTALL_PACKAGES) # this is needed to remove newlines


# installation script start
cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
#!/bin/bash
set -e

EOF


# functions
cp $GISLAB_ROOT/system/functions.sh $GISLAB_WORKER_IMAGE_BASE

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
source ./functions.sh

EOF


# sanity check
cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
if [ -f "/var/lib/gislab/installation.done" ]; then
	gislab_print_error "Installation is already done"
fi

EOF


# version
cp --parents /etc/gislab_version $GISLAB_WORKER_IMAGE_BASE

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
cp etc/gislab_version /etc/gislab_version
source /etc/gislab_version

EOF


# locales
cp --parents /etc/default/locale $GISLAB_WORKER_IMAGE_BASE

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
cp etc/default/locale /etc/default/locale

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
locale-gen en_US.UTF-8

EOF


# default DNS server
cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
echo "nameserver $GISLAB_SERVER_IP" > /etc/resolv.conf
echo "search gista.lan" >> /etc/resolv.conf

EOF


# timezone
cp --parents /etc/timezone $GISLAB_WORKER_IMAGE_BASE

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
cp etc/timezone /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

EOF


# packages installation
cp --parents /etc/apt/sources.list $GISLAB_WORKER_IMAGE_BASE

# apt-proxy
if [ -f /etc/apt/apt.conf.d/02proxy ]; then
	cp --parents /etc/apt/apt.conf.d/02proxy $GISLAB_WORKER_IMAGE_BASE
fi

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
cp etc/apt/sources.list /etc/apt/sources.list

if [ -f etc/apt/apt.conf.d/02proxy ]; then
	cp etc/apt/apt.conf.d/02proxy /etc/apt/apt.conf.d/02proxy
fi

apt-get update
apt-get --assume-yes --force-yes upgrade
apt-get --assume-yes --force-yes --no-install-recommends install $GISLAB_WORKER_INSTALL_PACKAGES

EOF


# network shares
cp --parents /etc/idmapd.conf $GISLAB_WORKER_IMAGE_BASE

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
cp etc/idmapd.conf /etc/idmapd.conf
service idmapd restart

echo "server.gis.lab:/storage/repository /mnt/repository nfs defaults 0 0" >> /etc/fstab
echo "server.gis.lab:/storage/share /mnt/share nfs defaults 0 0" >> /etc/fstab
echo "server.gis.lab:/storage/barrel /mnt/barrel nfs defaults 0 0" >> /etc/fstab

mkdir -p /mnt/repository && mount /mnt/repository
mkdir -p /mnt/share && mount /mnt/share
mkdir -p /mnt/barrel && mount /mnt/barrel

EOF
	

# GIS projections
cp -a --parents /usr/share/proj $GISLAB_WORKER_IMAGE_BASE
cp -a --parents /usr/share/gdal $GISLAB_WORKER_IMAGE_BASE

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
rm -rf /usr/share/proj
cp -a usr/share/proj /usr/share

# sync gdal files
rm -rf /usr/share/gdal
cp -a usr/share/gdal /usr/share

EOF


# mapserver
cp --parents /var/www/default/index.html $GISLAB_WORKER_IMAGE_BASE

cp --parents /etc/apache2/ports.conf $GISLAB_WORKER_IMAGE_BASE
cp --parents /etc/apache2/sites-available/default $GISLAB_WORKER_IMAGE_BASE
cp --parents /etc/apache2/sites-available/mapserver $GISLAB_WORKER_IMAGE_BASE

cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
mkdir -p /var/www/default
cp var/www/default/index.html /var/www/default/index.html
cp etc/apache2/ports.conf /etc/apache2/ports.conf
cp etc/apache2/sites-available/default /etc/apache2/sites-available/default
cp etc/apache2/sites-available/mapserver /etc/apache2/sites-available/mapserver

a2enmod rewrite
a2enmod expires
a2ensite default
a2ensite mapserver
service apache2 restart

EOF


# installation done
cat << EOF >> $GISLAB_WORKER_IMAGE_BASE/install.sh
mkdir -p /var/lib/gislab
echo "\$(gislab_config_header)" >> /var/lib/gislab/installation.done

EOF


# image creation
# to download and install use: 
# $ mkdir /tmp/install-worker && cd /tmp/install-worker && curl http://192.168.149.5/worker.tar.gz | tar xz -C /tmp/install-worker && bash ./install.sh && rm -rf /tmp/install-worker
tar czf $GISLAB_WORKER_IMAGE_ROOT/worker.tar.gz -C $GISLAB_WORKER_IMAGE_BASE .
ln -sf $GISLAB_WORKER_IMAGE_ROOT/worker.tar.gz /var/www/default/worker.tar.gz


# vim: set ts=4 sts=4 sw=4 noet: