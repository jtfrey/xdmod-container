#
# Singularity container-provisioning file for a container running a LAMP
# stack containing the XDMoD web application.
#
# Build
#
#   singularity build <path-to-image> Singularity
#
# Run
#
#   singularity instance start --overlay <path-to-writable-dir> --net --dns <dns-server-ip> \
#                              --network bridge --network-args "portmap=8080:8080/tcp" \
#                              <path-to-image> <instance-name>
#
# Initialize
#
#   singularity shell instance://<instance-name>
#       xdmod-setup
#       touch /var/lib/XDMoD-ingest-queue/in
#       touch /var/lib/XDMoD-ingest-queue/enable
#

Bootstrap: docker
From: centos:7

%labels
    Version         "8.1.2"
    Description     "XDMoD bundle containing database and web server" \
    Maintainer      "frey@udel.edu"

%files
    XDMoD-start /usr/sbin/XDMoD-start

%setup
    #
    # Install PhantomJS:
    #
    wget --directory-prefix=${SINGULARITY_ROOTFS}/tmp \
                https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
    tar -C ${SINGULARITY_ROOTFS}/tmp -xf ${SINGULARITY_ROOTFS}/tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2
    install --owner=0 --group=0 --mode=0755 --preserve-timestamps \
                ${SINGULARITY_ROOTFS}/tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs \
                ${SINGULARITY_ROOTFS}/usr/bin
    rm -rf      ${SINGULARITY_ROOTFS}/tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
                ${SINGULARITY_ROOTFS}/tmp/phantomjs-2.1.1-linux-x86_64

%post
    yum -y update
    yum -y install  epel-release
    yum -y install  sudo wget gmp-devel cronie logrotate fontconfig ghostscript \
                    coreutils shadow-utils tar xz bzip2 gzip zip jq \
                    java-1.8.0-openjdk java-1.8.0-openjdk-devel
    set -o pipefail && echo "root:${ROOT_PASSWORD}" | chpasswd

    #
    # Install Apache and PHP:
    #
    yum -y install  httpd php php-cli php-gd php-mcrypt php-gmp \
                    php-pdo php-xml php-pear-MDB2 php-pear-MDB2-Driver-mysql \
                    php-mbstring

    #
    # Install MySQL:
    #
    yum -y install  mariadb-server mariadb

    #
    # Install XDMoD:
    #
    yum -y install https://github.com/ubccr/xdmod/releases/download/v8.1.2/xdmod-8.1.2-1.0.el7.noarch.rpm

    #
    # Ensure a mountpoint/directory exists for the data ingest pipeline:
    #
    mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/in
    mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/out
    mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/error
    
    #
    # Make sure our entrypoint script is executable, etc:
    #
    chown 0:0 /usr/sbin/XDMoD-start
    chmod 0750 /usr/sbin/XDMoD-start

%startscript
   exec /usr/sbin/XDMoD-start "$@"

