#!mako|yaml

openstack-openvswitch-service:
  service:
    - running
    - enable: True
    - name: openvswitch
    - require:
      - pkg: openstack-quantum-openvswitch-pkg

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

% for env in ['eth1']:
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

  % for env in ['eth2']:
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