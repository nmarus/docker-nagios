#Dockerfile for Nagios
#https://github.com/nmarus/docker-nagios
#nmarus@gmail.com
FROM phusion/baseimage

# Setup APT
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-backports main restricted" >> /etc/apt/sources.list.d/non-free.list
RUN echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) multiverse" >> /etc/apt/sources.list.d/non-free.list

# Update, Install Prerequisites, Clean
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get upgrade -y && \
  apt-get install -y vim curl wget perl unzip git && \
  apt-get install -y build-essential apache2 apache2-utils php5-gd libgd2-xpm-dev libapache2-mod-php5 && \
  apt-get clean

# Install / Build Nagios
RUN useradd -m -s /bin/bash nagios --uid 1000 && \
  addgroup nagcmd && \
  adduser nagios nagcmd
RUN cd /tmp && \
  wget -q https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.1.1.tar.gz && \
  tar -zxvf nagios-4.1.1.tar.gz
RUN cd /tmp && \
  wget -q http://www.nagios-plugins.org/download/nagios-plugins-2.1.1.tar.gz && \
  tar -zxvf nagios-plugins-2.1.1.tar.gz
RUN mkdir -p /etc/httpd/conf.d/
RUN cd /tmp/nagios-4.1.1 && \
  ./configure --with-nagios-group=nagios --with-command-group=nagcmd && \
  make all && \
  make install && \
  make install-init && \ 
  make install-config && \ 
  make install-commandmode && \ 
  make install-webconf && \ 
  cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/  && \
  chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers  && \
  /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
RUN cd /tmp/nagios-plugins-2.1.1 && \
  ./configure --with-nagios-user=nagios --with-nagios-group=nagios && \
  make && \
  make install

# Setup nagios daemon
RUN mkdir /etc/service/nagios
COPY nagios.sh /etc/service/nagios/run
RUN chmod +x /etc/service/nagios/run
RUN sed -i 's,\$NagiosBin \-d \$NagiosCfgFile,\$NagiosBin \$NagiosCfgFile,' /etc/init.d/nagios
RUN sed -i 's,#cfg_file=/usr/local/nagios/etc/objects/windows.cfg,cfg_file=/usr/local/nagios/etc/objects/windows.cfg,' /usr/local/nagios/etc/nagios.cfg
RUN sed -i 's,#cfg_file=/usr/local/nagios/etc/objects/switch.cfg,cfg_file=/usr/local/nagios/etc/objects/switch.cfg,' /usr/local/nagios/etc/nagios.cfg

# Setup apache2 daemon
RUN echo "ServerName localhost" > /etc/apache2/conf-available/fqdn.conf
RUN ln -s /etc/apache2/conf-available/fqdn.conf /etc/apache2/conf-enabled/fqdn.conf
RUN mkdir /etc/service/apache2
COPY apache2.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run
RUN cp /etc/httpd/conf.d/nagios.conf /etc/apache2/conf-available/ && \
  rm -rf /etc/httpd && \
  cd /etc/apache2/conf-enabled && \
  ln -s ../conf-available/nagios.conf
RUN a2enmod cgi
RUN mv /var/www/html/index.html /var/www/html/index.php && \
  echo "<?php header('Location: /nagios');?>" > /var/www/html/index.php
RUN htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

# Enable SSH
RUN rm -f /etc/service/sshd/down

# Cleanup
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Service Ports
EXPOSE 22 80 161 162 5666 5667

# Start init system
CMD ["/sbin/my_init"]
