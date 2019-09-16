#
# XDMoD-start
#
# Docker container-provisioning file for a container running a LAMP
# stack containing the XDMoD web application.
#
# Build
#
#   $ docker build --rm --tag local/xdmod:8.1.2 .
#
# Run
#
#   $ docker run --detach --restart unless-stopped --name XDMoD-Caviness \
#     --volume "$(pwd)/ingest-queue:/var/lib/XDMoD-ingest-queue:rw" \
#     --volume "$(pwd)/database:/var/lib/mysql:rw" \
#     --publish 8080:8080 \
#     local/xdmod:8.1.2
#

FROM    centos:7
LABEL   version="8.1.2" \
        description="XDMoD bundle containing database and web server" \
        maintainer="frey@udel.edu"

#
# Install tools, libraries:
#
RUN     yum -y update
RUN     yum -y install  epel-release
RUN     yum -y install  sudo wget gmp-devel cronie logrotate fontconfig ghostscript \
                        coreutils shadow-utils tar xz bzip2 gzip zip jq \
                        java-1.8.0-openjdk java-1.8.0-openjdk-devel
RUN     set -o pipefail && echo "root:${ROOT_PASSWORD}" | chpasswd

#
# Install Apache and PHP:
#
RUN     yum -y install  httpd php php-cli php-gd php-mcrypt php-gmp \
                        php-pdo php-xml php-pear-MDB2 php-pear-MDB2-Driver-mysql \
                        php-mbstring

#
# Install PhantomJS:
#
ADD     https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 /tmp/
RUN     tar -C /tmp -xf /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN     install --owner=0 --group=0 --mode=0755 --preserve-timestamps \
                        /tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin
RUN     rm -rf /tmp/phantomjs-2.1.1-linux-x86_64

#
# Install MySQL:
#
RUN     yum -y install  mariadb-server mariadb

#
# Install XDMoD:
#
RUN     yum -y install https://github.com/ubccr/xdmod/releases/download/v8.1.2/xdmod-8.1.2-1.0.el7.noarch.rpm

#
# XDMoD uses an Apache virtual host on port 8080:
#
EXPOSE  8080/tcp

#
# Ensure a mountpoint/directory exists for the data ingest pipeline:
#
RUN     mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/in
RUN     mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/out
RUN     mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/error

#
# Command to execute when container is started:
#
COPY    --chown=0:0 XDMoD-start /usr/sbin/XDMoD-start
RUN     chmod 0755 /usr/sbin/XDMoD-start
CMD     /usr/sbin/XDMoD-start
