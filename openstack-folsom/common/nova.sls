#!mako|yaml

# openstack-folsom nova setup

include:
  - openstack-folsom.common.pkgs

<%
  openstack_folsom_mysql_root_username=pillar['openstack_folsom_mysql_root_username']
  openstack_folsom_mysql_root_password=pillar['openstack_folsom_mysql_root_password']

  openstack_folsom_keystone_ip=pillar['openstack_folsom_keystone_ip']
  openstack_folsom_keystone_auth_port=pillar['openstack_folsom_keystone_auth_port']

  openstack_folsom_keystone_service_token=pillar['openstack_folsom_keystone_service_token']
  openstack_folsom_keystone_service_endpoint=pillar['openstack_folsom_keystone_service_endpoint']
  openstack_folsom_keystone_service_tenant_name=pillar['openstack_folsom_keystone_service_tenant_name']

  openstack_folsom_glance_user=pillar['openstack_folsom_glance_user']
  openstack_folsom_glance_pass=pillar['openstack_folsom_glance_pass']

  openstack_folsom_quantum_user=pillar['openstack_folsom_quantum_user']
  openstack_folsom_quantum_pass=pillar['openstack_folsom_quantum_pass']

  openstack_folsom_nova_user=pillar['openstack_folsom_nova_user']
  openstack_folsom_nova_pass=pillar['openstack_folsom_nova_pass']

  openstack_folsom_OS_USERNAME=pillar['openstack_folsom_OS_USERNAME']
  openstack_folsom_OS_PASSWORD=pillar['openstack_folsom_OS_PASSWORD']
  openstack_folsom_OS_TENANT_NAME=pillar['openstack_folsom_OS_TENANT_NAME']
  openstack_folsom_keystone_ext_ip=pillar['openstack_folsom_keystone_ext_ip']

%>

openstack-nova-server-pkg:
  pkg.installed:
    - names: 
      - openstack-nova-api
      - openstack-nova-cert
      - openstack-nova-console
      - openstack-nova-scheduler
      - openstack-nova-novncproxy
      - novnc

#http://docs.saltstack.org/en/latest/ref/states/all/salt.states.user.html
#https://lists.launchpad.net/openstack/msg20762.html
#nova:x:162:162:OpenStack Nova Daemons:/var/lib/nova:/sbin/nologin
nova:
  user.present:
    - fullname: OpenStack Nova Daemons
    - shell: /sbin/nologin
    - home: /var/lib/nova
    - uid: 162
    - gid: 162
    - groups:
      - lock
    - require:
      - pkg: openstack-nova-server-pkg

openstack-nova-service:
  service:
    - running
    - enable: True
    - names:
% for svc in ['api', 'cert', 'console', 'consoleauth', 'metadata-api', 'novncproxy', 'scheduler', 'xvpvncproxy']:
      - openstack-nova-${svc}
% endfor
    - require:
      - pkg: openstack-nova-server-pkg

openstack-nova-db-create:
  cmd.run:
    - name: mysql -u root -e "CREATE DATABASE nova;"
    - unless: echo '' | mysql nova
    - require:
      - pkg: mysql-pkg
      - pkg: openstack-nova-server-pkg
    - watch_in:
      - cmd: openstack-nova-db-init

openstack-nova-db-init:
  cmd.run:
    - name: |
        mysql -u root -e "GRANT ALL ON nova.* TO '${openstack_folsom_nova_user}'@'%' IDENTIFIED BY '${openstack_folsom_nova_pass}';"
    - unless: |
        echo '' | mysql nova -u ${openstack_folsom_nova_user} -h 0.0.0.0 --password=${openstack_folsom_nova_pass}

openstack-nova-db-sync:
  cmd.wait:
    - name: nova-manage db sync
    - watch:
      - cmd: openstack-nova-db-init
      - cmd: openstack-nova-db-create

openstack-nova-api-paste-ini:
  file.managed:
    - name: /etc/nova/api-paste.ini
    - source: salt://openstack-folsom/files/nova-api-paste.ini
    - defaults:
        openstack_folsom_nova_user: ${openstack_folsom_nova_user}
        openstack_folsom_nova_pass: ${openstack_folsom_nova_pass}
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        openstack_folsom_keystone_service_tenant_name: ${openstack_folsom_keystone_service_tenant_name}
        openstack_folsom_keystone_auth_port: ${openstack_folsom_keystone_auth_port}
    - template: mako
    - require:
      - pkg: openstack-nova-server-pkg
    - watch_in:
      - service: openstack-nova-service

openstack-nova-conf:
  file.managed:
    - name: /etc/nova/nova.conf
    - source: salt://openstack-folsom/files/nova.conf
    - defaults:
        openstack_folsom_nova_user: ${openstack_folsom_nova_user}
        openstack_folsom_nova_pass: ${openstack_folsom_nova_pass}
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        openstack_folsom_keystone_service_tenant_name: ${openstack_folsom_keystone_service_tenant_name}
        openstack_folsom_keystone_auth_port: ${openstack_folsom_keystone_auth_port}
        openstack_folsom_keystone_ext_ip: ${openstack_folsom_keystone_ext_ip}
        openstack_folsom_quantum_user: ${openstack_folsom_quantum_user}
        openstack_folsom_quantum_pass: ${openstack_folsom_quantum_pass}
    - template: mako
    - require:
      - pkg: openstack-nova-server-pkg
    - watch_in:
      - service: openstack-nova-service

