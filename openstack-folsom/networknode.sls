#!mako|yaml

# openstack-folsom networknode setup

include:
  - openstack-folsom.common.openstackcommon
  - openstack-folsom.common.quantum
  - openstack-folsom.common.openvswitch-bridges-networknode

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

quantum-dhcp-agent-service:
  service:
    - running
    - enable: True
    - name: quantum-dhcp-agent
    - require:
      - pkg: openstack-quantum-openvswitch-pkg

openstack-quantum-l3_agent-ini:
  file.managed:
    - name: /etc/quantum/l3_agent.ini
    - source: salt://saltmine/files/openstack/l3_agent.ini
    - defaults:
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
        openstack_folsom_keystone_auth_port: ${openstack_folsom_keystone_auth_port}
        openstack_folsom_keystone_ext_ip: ${openstack_folsom_keystone_ext_ip}
        openstack_folsom_keystone_metadata_port: ${openstack_folsom_keystone_metadata_port}
        openstack_folsom_keystone_service_tenant_name: ${openstack_folsom_keystone_service_tenant_name} 
        openstack_folsom_quantum_user: ${openstack_folsom_quantum_user}
        openstack_folsom_quantum_pass: ${openstack_folsom_quantum_pass}
    - template: mako
    - require:
      - pkg: openstack-quantum-openvswitch-pkg
    - watch_in:
      - service: quantum-l3-agent-service

openstack-quantum-conf:
  file.managed:
    - name: /etc/quantum/quantum.conf
    - source: salt://saltmine/files/openstack/quantum.conf
    - defaults:
        openstack_folsom_keystone_ip: ${openstack_folsom_keystone_ip}
    - template: mako
    - require:
      - pkg: openstack-quantum-openvswitch-pkg
    - watch_in:
      - service: quantum-openvswitch-agent-service

quantum-l3-agent-service:
  service:
    - running
    - enable: True
    - name: quantum-l3-agent
    - require:
      - pkg: openstack-quantum-openvswitch-pkg