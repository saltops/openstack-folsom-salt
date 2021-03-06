#!mako|yaml

# openstack-folsom keystone setup

include:
  - openstack-folsom.common.pkgs

<%
  openstack_folsom_mysql_root_username=pillar['openstack_folsom_mysql_root_username']
  openstack_folsom_mysql_root_password=pillar['openstack_folsom_mysql_root_password']

  openstack_folsom_keystone_user=pillar['openstack_folsom_keystone_user']
  openstack_folsom_keystone_pass=pillar['openstack_folsom_keystone_pass']
  openstack_folsom_keystone_ip=pillar['openstack_folsom_keystone_ip']

  openstack_folsom_keystone_service_token=pillar['openstack_folsom_keystone_service_token']
  openstack_folsom_keystone_service_endpoint=pillar['openstack_folsom_keystone_service_endpoint']
  openstack_folsom_keystone_service_tenant_name=pillar['openstack_folsom_keystone_service_tenant_name']

  openstack_folsom_OS_USERNAME=pillar['openstack_folsom_OS_USERNAME']
  openstack_folsom_OS_PASSWORD=pillar['openstack_folsom_OS_PASSWORD']
  openstack_folsom_OS_TENANT_NAME=pillar['openstack_folsom_OS_TENANT_NAME']
  openstack_folsom_keystone_ext_ip=pillar['openstack_folsom_keystone_ext_ip']

%>

mysql-pkg:
  pkg.installed:
    - names: 
      - mysql55-server
% if pillar['openstack_folsom_source'] == 'internet':
    - require:
      - pkg: ius-repo
% endif

python-mysqldb-pkg:
  pkg.installed:
    - names: 
      - MySQL-python
# on Ubuntu
#      - python-mysqldb
    - require: 
      - pkg: mysql-pkg

mysql-service:
  service:
    - name: mysqld
    - running
    - enable: True
    - require:
      - pkg: mysql-pkg

rabbitmq-server-pkg:
  pkg.installed:
    - names: 
      - rabbitmq-server
% if pillar['openstack_folsom_source'] == 'internet':
    - require:
      - pkg: epel-repo
% endif

rabbitmq-server-service:
  service:
    - running
    - enable: True
    - names: 
      - rabbitmq-server
    - require: 
      - pkg: rabbitmq-server-pkg

openstack-keystone-pkg:
  pkg.installed:
    - names:
      - openstack-keystone
    - require:
      - service: mysql-service

keystone-db-create:
  cmd.run:
    - name: mysql -u root -e "CREATE DATABASE keystone;"
    - unless: echo '' | mysql keystone
    - require:
      - pkg: mysql-pkg
      - pkg: openstack-keystone-pkg
    - watch_in:
      - cmd: keystone-db-init

keystone-db-init:
  cmd.run:
    - name: | 
        mysql -u root -e "GRANT ALL ON keystone.* TO '${openstack_folsom_keystone_user}'@'%' IDENTIFIED BY '${openstack_folsom_keystone_pass}';"
    - unless: |
        echo '' | mysql keystone -u ${openstack_folsom_keystone_user} -h 0.0.0.0 --password=${openstack_folsom_keystone_pass}

keystone-conf:
  file.managed:
    - name: /etc/keystone/keystone.conf
    - source: salt://openstack-folsom/files/keystone.conf
    - defaults:
        openstack_folsom_keystone_user: ${openstack_folsom_keystone_user}
        openstack_folsom_keystone_pass: ${openstack_folsom_keystone_pass}
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        openstack_folsom_keystone_service_tenant_name: ${openstack_folsom_keystone_service_tenant_name}
        openstack_folsom_keystone_ext_ip: ${openstack_folsom_keystone_ext_ip}
    - template: mako
    - require:
      - pkg: openstack-keystone-pkg
    - watch_in:
      - service: openstack-keystone-service

openstack-keystone-service:
  service:
    - running
    - enable: True
    - name: openstack-keystone
    - require:
      - pkg: openstack-keystone-pkg

keystone-db-sync:
  cmd.wait:
    - name: keystone-manage db_sync
    - watch:
      - cmd: keystone-db-init
      - cmd: keystone-db-create
      - file: keystone-conf

keystone-basic-script:
  file.managed:
    - name: /root/keystone-basic.sh
    - source: salt://openstack-folsom/files/keystone-basic.sh
    - template: mako
    - defaults:
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        openstack_folsom_OS_PASSWORD: ${openstack_folsom_OS_PASSWORD}
        openstack_folsom_OS_TENANT_NAME: ${openstack_folsom_OS_TENANT_NAME}
        openstack_folsom_keystone_service_tenant_name: ${openstack_folsom_keystone_service_tenant_name}
    - require:
      - service: openstack-keystone-service
  cmd.wait:
    - name: sh /root/keystone-basic.sh
    - watch:
      - cmd: keystone-db-sync
    - require:
      - file: keystone-basic-script

keystone-endpoints-script:
  file.managed:
    - name: /root/keystone-endpoints-basic.sh
    - source: salt://openstack-folsom/files/keystone-endpoints-basic.sh
    - template: mako
    - defaults:
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        openstack_folsom_keystone_ext_ip: ${openstack_folsom_keystone_ext_ip}
        openstack_folsom_keystone_user: ${openstack_folsom_keystone_user}
        openstack_folsom_keystone_pass: ${openstack_folsom_keystone_pass}
    - require:
      - service: openstack-keystone-service
  cmd.wait:
    - name: sh /root/keystone-endpoints-basic.sh
    - watch:
      - cmd: keystone-basic-script
    - require:
      - file: keystone-endpoints-script

keystone-creds-script:
  file.managed:
    - name: /root/keystonerc
    - source: salt://openstack-folsom/files/keystonerc
    - template: mako
    - defaults:
        openstack_folsom_OS_USERNAME: ${openstack_folsom_OS_USERNAME}
        openstack_folsom_OS_PASSWORD: ${openstack_folsom_OS_PASSWORD}
        openstack_folsom_OS_TENANT_NAME: ${openstack_folsom_OS_TENANT_NAME}
        openstack_folsom_keystone_ext_ip: ${openstack_folsom_keystone_ext_ip}
    - require:
      - service: openstack-keystone-service
  cmd.wait:
    - name: source /root/keystonerc
    - watch:
      - cmd: keystone-endpoints-script
    - require:
      - file: keystone-creds-script