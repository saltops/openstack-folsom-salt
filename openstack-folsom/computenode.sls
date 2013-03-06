#!mako|yaml

# openstack-folsom networknode setup

include:
  - openstack-folsom.common.openstackcommon
  - openstack-folsom.common.quantum
  - openstack-folsom.common.openvswitch-bridges
  - openstack-folsom.common.nova-compute
  - openstack-folsom.common.cinder

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
  openstack_folsom_keystone_metadata_port=pillar['openstack_folsom_keystone_metadata_port']
%>

openstack-quantum-service:
  service:
    - dead
    - enable: False
    - name: quantum-server
    - require:
      - pkg: openstack-quantum-openvswitch-pkg

quantum-openvswitch-agent-service:
  service:
    - running
    - enable: True
    - name: quantum-openvswitch-agent
    - require:
      - pkg: openstack-quantum-openvswitch-pkg
    - watch:
      - file: openstack-quantum-ovs_quantum_plugin-ini

openstack-nova-compute-service:
  service:
    - running
    - enable: True
    - name: openstack-nova-compute
    - require:
      - pkg: openstack-quantum-openvswitch-pkg

openstack-quantum-conf:
  file.managed:
    - name: /etc/quantum/quantum.conf
    - source: salt://openstack-folsom/files/quantum.conf
    - defaults:
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
    - template: mako
    - require:
      - pkg: openstack-quantum-openvswitch-pkg
    - watch_in:
      - service: quantum-openvswitch-agent-service


#----------------------------
# Setup Nova for Compute
#----------------------------

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
      - pkg: openstack-quantum-openvswitch-pkg
    - watch_in:
      - service: openstack-nova-compute-service

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
      - pkg: openstack-quantum-openvswitch-pkg
    - watch_in:
      - service: openstack-nova-compute-service

