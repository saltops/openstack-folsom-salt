#!mako|yaml

# openstack-folsom horizon setup

include:
  - saltmine.pkgs.epel
  - saltmine.pkgs.percona
  - saltmine.pkgs.ius

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

openstack-dashboard-pkg:
  pkg.installed:
    - names: 
      - openstack-dashboard
    - require: 
      - pkg: epel-repo

memcached-pkg:
  pkg.installed:
    - names: 
      - memcached
    - require: 
      - pkg: epel-repo

memcached-service:
  service:
    - running
    - enable: True
    - name: memcached

openstack-dashboard-service:
  service:
    - running
    - enable: True
    - name: httpd
    - require:
      - pkg: openstack-dashboard-pkg

