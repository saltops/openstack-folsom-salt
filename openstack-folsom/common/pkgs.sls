#!mako|yaml


% if pillar['openstack_folsom_source'] == 'internet':

epel-repo:
  pkg.installed:
    - name: epel-release
    - sources:
      - epel-release: 'http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'

percona-repo:
  pkg.installed:
    - name: percona
    - sources:
      - percona-release: 'http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm'
      - percona-testing: 'http://repo.percona.com/testing/centos/6/os/noarch/percona-testing-0.0-1.noarch.rpm'

% endif