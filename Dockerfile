FROM python:2.7.12
MAINTAINER = Di Xu <stephenhsu90@gmail.com>

EXPOSE 5000 35357 11211
ENV KEYSTONE_VERSION 14.0.1
ENV KEYSTONE_ADMIN_PASSWORD passw0rd
ENV KEYSTONE_DB_ROOT_PASSWD passw0rd
ENV KEYSTONE_DB_PASSWD passw0rd

LABEL version="$KEYSTONE_VERSION"
LABEL description="Openstack Keystone Docker Image Supporting HTTP/HTTPS"

RUN apt-get -y update \
    && apt-get install -y apache2 libapache2-mod-wsgi git memcached\
        libffi-dev python-dev libssl-dev mysql-client libldap2-dev libsasl2-dev\
    && apt-get -y clean

RUN export DEBIAN_FRONTEND="noninteractive" \
    && echo "mysql-server mysql-server/root_password password $KEYSTONE_DB_ROOT_PASSWD" | debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password $KEYSTONE_DB_ROOT_PASSWD" | debconf-set-selections \
    && apt-get -y update && apt-get install -y mysql-server && apt-get -y clean

RUN git clone -b ${KEYSTONE_VERSION} https://github.com/openstack/keystone.git

WORKDIR /keystone
RUN pip install -r requirements.txt \
    && PBR_VERSION=${KEYSTONE_VERSION} python setup.py install

RUN pip install osc-lib python-openstackclient PyMySql python-memcached \
    python-ldap ldappool
RUN mkdir /etc/keystone
RUN cp -r ./etc/* /etc/keystone/

COPY ./etc/keystone.conf /etc/keystone/keystone.conf
COPY keystone.sql /keystone.sql
COPY bootstrap.sh /bootstrap.sh
COPY ./keystone.wsgi.conf /etc/apache2/sites-available/keystone.conf

WORKDIR /root
CMD sh -x /bootstrap.sh
