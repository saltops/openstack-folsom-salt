#!mako|yaml


% if pillar['openstack_folsom_source'] == 'internet':

epel-repo:
  pkg.installed:
    - name: epel-release
    - sources:
      - epel-release: ${pillar['repo-epel-release']}
    - require_in:
      - pkg: openstack-glance-pkg
      - pkg: rabbitmq-server-pkg
      - pkg: openstack-keystone-pkg
      - pkg: openstack-nova-server-pkg
      - pkg: openstack-dashboard-pkg
      - pkg: memcached-pkg
      - pkg: openvswitch-deps-pkg
      - pkg: openstack-quantum-pkg

percona-repo:
  pkg.installed:
    - name: percona
    - sources:
      - percona-release: ${pillar['repo-percona-release']}
      - percona-testing: ${pillar['repo-percona-testing']}

ius-repo:
  pkg.installed:
    - name: ius-release
    - sources:
      - ius-release: ${pillar['repo-ius-release']}
    - require_in:
      - pkg: mysql-pkg

% endif