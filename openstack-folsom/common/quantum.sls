#!mako|yaml

# openstack-folsom quantum setup

include:
  - openstack-folsom.common.openstackcommon
  - openstack-folsom.common.pkgs
  - openstack-folsom.common.openvswitch

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


  openstack_folsom_OS_USERNAME=pillar['openstack_folsom_OS_USERNAME']
  openstack_folsom_OS_PASSWORD=pillar['openstack_folsom_OS_PASSWORD']
  openstack_folsom_OS_TENANT_NAME=pillar['openstack_folsom_OS_TENANT_NAME']
  openstack_folsom_keystone_ext_ip=pillar['openstack_folsom_keystone_ext_ip']

%>


openstack-quantum-pkg:
  pkg.installed:
    - names: 
      - openstack-quantum

openstack-quantum-openvswitch-pkg:
  pkg.installed:
    - names: 
      - openstack-quantum-openvswitch
    - require:
      - pkg: openstack-quantum-pkg
      - pkg: openvswitch-userspace-pkg
      - pkg: openvswitch-kernel-pkg

# only install database if we're on the control node
% if 'openstack-control' in grains['roles']:

openstack-quantum-service:
  service:
    - running
    - enable: True
    - name: quantum-server
    - require:
      - pkg: openstack-quantum-openvswitch-pkg
    - watch:
      - file: openstack-quantum-api-paste-ini
      - file: openstack-quantum-ovs_quantum_plugin-ini

openstack-quantum-db-create:
  cmd.run:
    - name: mysql -u root -e "CREATE DATABASE quantum;"
    - unless: echo '' | mysql quantum
    - require:
      - pkg: mysql-pkg
      - pkg: openstack-quantum-pkg
    - watch_in:
      - cmd: openstack-quantum-db-init

openstack-quantum-db-init:
  cmd.run:
    - name: |
        mysql -u root -e "GRANT ALL ON quantum.* TO '${openstack_folsom_quantum_user}'@'%' IDENTIFIED BY '${openstack_folsom_quantum_pass}';"
    - unless: |
        echo '' | mysql quantum -u ${openstack_folsom_quantum_user} -h 0.0.0.0 --password=${openstack_folsom_quantum_pass}

% endif

openstack-quantum-ovs_quantum_plugin-ini:
  file.managed:
    - name: /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    - source: salt://saltmine/files/openstack/ovs_quantum_plugin.ini
    - defaults:
        openstack_folsom_quantum_user: ${openstack_folsom_quantum_user}
        openstack_folsom_quantum_pass: ${openstack_folsom_quantum_pass}
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        grains: ${grains}
    - template: mako
    - require:
      - pkg: openstack-quantum-openvswitch-pkg

openstack-quantum-api-paste-ini:
  file.managed:
    - name: /etc/quantum/api-paste.ini
    - source: salt://saltmine/files/openstack/quantum-api-paste.ini
    - defaults:
        openstack_folsom_quantum_user: ${openstack_folsom_quantum_user}
        openstack_folsom_quantum_pass: ${openstack_folsom_quantum_pass}
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        openstack_folsom_keystone_service_tenant_name: ${openstack_folsom_keystone_service_tenant_name}
    - template: mako
    - require:
      - pkg: openstack-quantum-openvswitch-pkg
