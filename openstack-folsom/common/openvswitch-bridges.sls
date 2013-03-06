#!mako|yaml

include:
  - openstack-folsom.common.quantum

<%
interface1_device=salt['cmd.run']('for i in 1 2 3; do ifconfig eth$i 2>&1 | grep '+pillar['interface1_range']+' > /dev/null && echo eth$i; done;')
interface2_device=salt['cmd.run']('for i in 1 2 3; do ifconfig eth$i 2>&1 | grep '+pillar['interface2_range']+' > /dev/null && echo eth$i; done;')
interface3_device=salt['cmd.run']('for i in 1 2 3; do ifconfig eth$i 2>&1 | grep '+pillar['interface3_range']+' > /dev/null && echo eth$i; done;')

# Notes:
# for i in 1 2 3; do ifconfig eth$i 2>&1 | grep 100.10.10 > /dev/null && echo eth$i; done;

%>

#https://sites.google.com/site/routeflow/my-page
linux-bridge-disable:
  cmd.run:
    - name: rmmod bridge
    - unless: |
        cat /proc/modules | grep bridge || echo 'bridge module not installed'
    - require:
      - pkg: openstack-quantum-openvswitch-pkg


openstack-openvswitch-service:
  service:
    - running
    - enable: True
    - name: openvswitch
    - require:
      - pkg: openstack-quantum-openvswitch-pkg
      - cmd: linux-bridge-disable

openstack-node-br-int-bridge:
  cmd.run:
    - name: ovs-vsctl add-br br-int
    - unless: ovs-vsctl list-br | grep 'br-int'
    - require:
      - service: openstack-openvswitch-service

openstack-node-br-eth1-bridge:
  cmd.run:
    - name: ovs-vsctl add-br br-eth1
    - unless: ovs-vsctl list-br | grep 'br-eth1'
    - require:
      - service: openstack-openvswitch-service

% for env in [interface2_device]:
openstack-node-br-eth1-port:
  cmd.run:
    - name: ovs-vsctl add-port br-eth1 ${env}
    - unless: |
        [[ `ovs-vsctl list-ports br-eth1 2> /dev/null | grep '^${env}$'` == '${env}' ]] && echo '${env} port exists'
    - require:
      - service: openstack-openvswitch-service
      - cmd: openstack-node-br-eth1-bridge
% endfor

% if ('openstack-network' in grains['roles']):
openstack-node-br-ex-bridge:
  cmd.run:
    - name: ovs-vsctl add-br br-ex
    - unless: ovs-vsctl list-br | grep 'br-ex'
    - require:
      - service: openstack-openvswitch-service

  % for env in [interface3_device]:
openstack-node-br-ex-port:
  cmd.run:
    - name: ovs-vsctl add-port br-ex ${env}
    - unless: |
        [[ `ovs-vsctl list-ports br-ex 2> /dev/null | grep '^${env}$'` == '${env}' ]] && echo '${env} port exists'
    - require:
      - service: openstack-openvswitch-service
      - cmd: openstack-node-br-ex-bridge
  % endfor

% endif