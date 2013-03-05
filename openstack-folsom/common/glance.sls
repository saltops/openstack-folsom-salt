#!mako|yaml

# openstack-folsom glance setup

include:
  - openstack-folsom.common.pkgs

<%
  openstack_folsom_mysql_root_username=pillar['openstack_folsom_mysql_root_username']
  openstack_folsom_mysql_root_password=pillar['openstack_folsom_mysql_root_password']

  openstack_folsom_glance_user=pillar['openstack_folsom_glance_user']
  openstack_folsom_glance_pass=pillar['openstack_folsom_glance_pass']
  openstack_folsom_keystone_ip=pillar['openstack_folsom_keystone_ip']
  openstack_folsom_keystone_auth_port=pillar['openstack_folsom_keystone_auth_port']

  openstack_folsom_keystone_service_token=pillar['openstack_folsom_keystone_service_token']
  openstack_folsom_keystone_service_endpoint=pillar['openstack_folsom_keystone_service_endpoint']
  openstack_folsom_keystone_service_tenant_name=pillar['openstack_folsom_keystone_service_tenant_name']

  openstack_folsom_OS_USERNAME=pillar['openstack_folsom_OS_USERNAME']
  openstack_folsom_OS_PASSWORD=pillar['openstack_folsom_OS_PASSWORD']
  openstack_folsom_OS_TENANT_NAME=pillar['openstack_folsom_OS_TENANT_NAME']
  openstack_folsom_keystone_ext_ip=pillar['openstack_folsom_keystone_ext_ip']

%>

openstack-glance-pkg:
  pkg.installed:
    - names: 
      - openstack-glance
    - require: 
      - pkg: epel-repo

openstack-glance-db-create:
  cmd.run:
    - name: mysql -u root -e "CREATE DATABASE glance;"
    - unless: echo '' | mysql glance
    - require:
      - pkg: mysql-pkg
      - pkg: openstack-glance-pkg
    - watch_in:
      - cmd: openstack-glance-db-init

openstack-glance-db-init:
  cmd.run:
    - name: |
        mysql -u root -e "GRANT ALL ON glance.* TO '${openstack_folsom_glance_user}'@'%' IDENTIFIED BY '${openstack_folsom_glance_pass}';"
    - unless: |
        echo '' | mysql glance -u ${openstack_folsom_glance_user} -h 0.0.0.0 --password=${openstack_folsom_glance_pass}

openstack-glance-db-sync:
  cmd.wait:
    - name: glance-manage db_sync
    - watch:
      - cmd: openstack-glance-db-init
      - cmd: openstack-glance-db-create

% for svc in ['api','registry']:
openstack-glance-${svc}-service:
  service:
    - running
    - enable: True
    - name: openstack-glance-${svc}
    - require:
      - pkg: openstack-glance-pkg
% endfor

openstack-glance-api-paste-ini1:
  file.comment:
    - name: /etc/glance/glance-api-paste.ini
    - char: '#'
    - regex: '^delay_auth_decision = true'
    - require:
      - pkg: openstack-glance-pkg
    - watch_in:
      - service: openstack-glance-api-service
      - service: openstack-glance-registry-service
      - cmd: openstack-glance-db-sync

openstack-glance-api-paste-ini2:
  file.append:
    - name: /etc/glance/glance-api-paste.ini
    - text:
      - '[filter:authtoken]'
      - 'paste.filter_factory = keystone.middleware.auth_token:filter_factory'
      - 'auth_host = ${openstack_folsom_keystone_ip}'
      - 'auth_port = 35357'
      - 'auth_protocol = http'
      - 'admin_tenant_name = ${openstack_folsom_keystone_service_tenant_name}'
      - 'admin_user = ${openstack_folsom_glance_user}'
      - 'admin_password = ${openstack_folsom_OS_PASSWORD}'
    - require:
      - file: openstack-glance-api-paste-ini1
    - watch_in:
      - service: openstack-glance-api-service
      - service: openstack-glance-registry-service
      - cmd: openstack-glance-db-sync

openstack-glance-registry-paste-ini:
  file.append:
    - name: /etc/glance/glance-registry-paste.ini
    - text:
      - '[filter:authtoken]'
      - 'paste.filter_factory = keystone.middleware.auth_token:filter_factory'
      - 'auth_host = ${openstack_folsom_keystone_ip}'
      - 'auth_port = 35357'
      - 'auth_protocol = http'
      - 'admin_tenant_name = ${openstack_folsom_keystone_service_tenant_name}'
      - 'admin_user = ${openstack_folsom_glance_user}'
      - 'admin_password = ${openstack_folsom_OS_PASSWORD}'
    - require:
      - file: openstack-glance-api-paste-ini2
    - watch_in:
      - service: openstack-glance-api-service
      - service: openstack-glance-registry-service
      - cmd: openstack-glance-db-sync

openstack-glance-api-conf1:
  file.sed:
    - name: /etc/glance/glance-api.conf
    - before: 'mysql:.*'
    - after: 'mysql://${openstack_folsom_glance_user}:${openstack_folsom_glance_pass}@${openstack_folsom_keystone_ip}/glance'
    - limit: '^sql_connection\ =\ '
    - require:
      - pkg: openstack-glance-pkg
    - watch_in:
      - service: openstack-glance-api-service
      - service: openstack-glance-registry-service
      - cmd: openstack-glance-db-sync

openstack-glance-api-conf2:
  file.append:
    - name: /etc/glance/glance-api.conf
    - text:
      - 'flavor = keystone'
    - require:
      - file: openstack-glance-api-conf1
    - watch_in:
      - service: openstack-glance-api-service
      - service: openstack-glance-registry-service
      - cmd: openstack-glance-db-sync

openstack-glance-registry-conf1:
  file.sed:
    - name: /etc/glance/glance-registry.conf
    - before: 'mysql:.*'
    - after: 'mysql://${openstack_folsom_glance_user}:${openstack_folsom_glance_pass}@${openstack_folsom_keystone_ip}/glance'
    - limit: '^sql_connection\ =\ '
    - require:
      - pkg: openstack-glance-pkg
    - watch_in:
      - service: openstack-glance-api-service
      - service: openstack-glance-registry-service
      - cmd: openstack-glance-db-sync

openstack-glance-registry-conf2:
  file.append:
    - name: /etc/glance/glance-registry.conf
    - text:
      - 'flavor = keystone'
    - require:
      - file: openstack-glance-registry-conf1
    - watch_in:
      - service: openstack-glance-api-service
      - service: openstack-glance-registry-service
      - cmd: openstack-glance-db-sync