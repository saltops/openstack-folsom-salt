## OpenStack settings
openstack_folsom_source: 'internet'

# Sources
repo-epel-release: 'http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
repo-percona-release: 'http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm'
repo-percona-testing: 'http://repo.percona.com/testing/centos/6/os/noarch/percona-testing-0.0-1.noarch.rpm'
repo-ius-release: 'http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-10.ius.el6.noarch.rpm'
openvswitch-file-location: 'http://openvswitch.org/releases'

# MySQL
openstack_folsom_mysql_root_username: 'root'
openstack_folsom_mysql_root_password: 'test'

# Keystone
openstack_folsom_keystone_user: 'keystone'
openstack_folsom_keystone_pass: 'key2013'
openstack_folsom_keystone_service_token: 27af01e78eaa2f9ee947
openstack_folsom_keystone_admin_token: 27af01e78eaa2f9ee947
openstack_folsom_keystone_service_tenant_name: 'service'
openstack_folsom_keystone_service_endpoint: 'http://127.0.0.1:35357/v2.0'

openstack_folsom_keystone_ip: '100.10.10.51'
openstack_folsom_keystone_ext_ip: '192.168.100.51'
openstack_folsom_keystone_auth_port: '35357'
openstack_folsom_keystone_metadata_port: '8775'

openstack_folsom_OS_USERNAME: 'admin'
openstack_folsom_OS_PASSWORD: '1234'
openstack_folsom_OS_TENANT_NAME: 'admin'

# Glance
openstack_folsom_glance_user: 'glance'
openstack_folsom_glance_pass: 'gla2013'

# Quantum
openstack_folsom_quantum_user: 'quantum'
openstack_folsom_quantum_pass: 'qua2013'

# Nova
openstack_folsom_nova_user: 'nova'
openstack_folsom_nova_pass: 'nov2013'

# Cinder
openstack_folsom_cinder_user: 'cinder'
openstack_folsom_cinder_pass: 'cin2013'