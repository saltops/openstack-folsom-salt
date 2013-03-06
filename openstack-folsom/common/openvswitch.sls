#!mako|yaml

<%
openvswitch_release='1.7.3'
openvswitch_release_full='openvswitch-'+openvswitch_release
home_directory='/root'
openvswitch_source_directory=home_directory+'/rpmbuild/SOURCES'
openvswitch_filename='openvswitch-'+openvswitch_release+'.tar.gz'
openvswitch_temp_directory=home_directory+'/openvswitch-'+openvswitch_release
openvswitch_file_location=pillar['openvswitch-file-location']
%>

#-----------------------------------------------------------
# Openvswitch kernel and userspace rpm build/install script
# Compatible with RHEL/CentOS 6.3
#-----------------------------------------------------------

#http://openvswitch.org/download/

openvswitch-deps-pkg:
  pkg.installed:
    - names: 
      - gcc
      - make
      - python-devel
      - openssl-devel
      - kernel-devel
      - kernel-debug-devel
      - rpm-build
      - redhat-rpm-config
      - crash-devel
      - crash

#---------------------------
# Create rpmbuild directory
#---------------------------

#mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
% for directory in ['BUILD', 'RPMS', 'SOURCES', 'SPECS', 'SRPMS']:

rpmbuild-${directory}-directory:
  cmd.run:
    - name: mkdir -p ${home_directory}/rpmbuild/${directory}
    - unless: |
        [[ -d ${home_directory}/rpmbuild/${directory} ]] && echo 'exists'
    - require:
      - pkg: openvswitch-deps-pkg
    - require_in:
      - cmd: openvswitch-download-source-tarball
      - cmd: openvswitch-download-temp-tarball

% endfor


#---------------------------
# Download tarballs
#---------------------------

#http://www.cyberciti.biz/faq/bash-csh-sh-check-and-file-file-size/
openvswitch-download-temp-tarball:
  cmd.run:
    - name: |
        curl ${openvswitch_file_location}/${openvswitch_filename} > ~/${openvswitch_filename}
    - unless: |
        [[ `stat -c %s ${home_directory}/${openvswitch_filename}` -gt 2150000 ]] && echo 'big file exists'
    - require:
      - pkg: openvswitch-deps-pkg

openvswitch-unzip-tarball:
  cmd.run:
    - name: tar -xvf ${home_directory}/${openvswitch_filename}
    - unless: |
        [[ `du -s /root/openvswitch-1.7.3 | cut -d$'\t'  -f1 2>&1` -gt 14000 ]] && echo 'directory is big'
    - require:
      - cmd: openvswitch-download-temp-tarball

openvswitch-download-source-tarball:
  cmd.run:
    - name: |
        curl ${openvswitch_file_location}/${openvswitch_filename} > ${openvswitch_source_directory}/${openvswitch_filename}
    - unless: |
        [[ `stat -c %s ${openvswitch_source_directory}/${openvswitch_filename}` -gt 2150000 ]] && echo 'big file exists'
    - require:
      - pkg: openvswitch-deps-pkg

#---------------------------
# Patch source tarball
#---------------------------

#http://networkstatic.net/open-vswitch-red-hat-installation/
#http://stackoverflow.com/questions/1825905/comment-out-n-lines-with-sed-awk
openvswitch-fix1:
  cmd.run:
    - name: |
        sed '/^static inline struct page \*skb_frag_page/,+3 s.^.//.' ./skbuff.h > ./skbuff.h_bak && cp -f skbuff.h_bak skbuff.h && diff skbuff.h_bak skbuff.h
    - unless: |
        grep -i '\/\/static inline struct page \*skb_frag_page' skbuff.h && echo 'edit already exists'
    - cwd: ${openvswitch_temp_directory}/datapath/linux/compat/include/linux/
    - require:
      - cmd: openvswitch-download-temp-tarball
      - cmd: openvswitch-download-source-tarball
      - cmd: openvswitch-unzip-tarball

# copy out a tar from the tar.gz file
openvswitch-sourcetar-copy:
  cmd.run:
    - name: |
        gunzip -c ${openvswitch_source_directory}/${openvswitch_release_full}.tar.gz > ${openvswitch_source_directory}/${openvswitch_release_full}.tar
    - unless: |
        [[ `stat -c %s ${openvswitch_source_directory}/${openvswitch_release_full}.tar.gz` -gt 2150000 ]] && [[ `stat -c %s ${openvswitch_source_directory}/${openvswitch_release_full}.tar` -gt 13680000 ]] && echo 'both big files exist'
    - require:
      - cmd: openvswitch-fix1

# add the new patched file to the tar if only one skbuff.h exists in the tar
openvswitch-fixtar:
  cmd.run:
    - name: |
        tar -rf ${openvswitch_source_directory}/${openvswitch_release_full}.tar ./${openvswitch_release_full}/datapath/linux/compat/include/linux/skbuff.h
    - unless: |
        [[ `tar --list -f ${openvswitch_source_directory}/${openvswitch_release_full}.tar | grep skbuff.h | wc -l` -gt 1 ]] && echo 'more than one'
    - cwd: ${home_directory}
    - require:
      - cmd: openvswitch-fix1
      - cmd: openvswitch-sourcetar-copy

# gzip new tar
openvswitch-gzip-tar:
  cmd.wait:
    - name: |
        gzip -c ${openvswitch_source_directory}/openvswitch-1.7.3.tar > ${openvswitch_source_directory}/${openvswitch_release_full}.tar2.gz && [[ `stat -c %s ${openvswitch_source_directory}/${openvswitch_release_full}.tar2.gz` -gt 2150000 ]] && echo 'big file exists'
    - unless: |
        [[ `stat -c %s ${openvswitch_source_directory}/${openvswitch_release_full}.tar2.gz` -gt 2150000 ]] && echo 'big file exists'
    - cwd: ${home_directory}
    - watch:
      - cmd: openvswitch-fixtar
    - require_in:
      - cmd: openvswitch-copy-gzip

# compare to new tar to size of old tar. if same, then good! if not, copy new tar over old tar
openvswitch-copy-gzip:
  cmd.run:
    - name: |
        cp -f ${openvswitch_source_directory}/${openvswitch_release_full}.tar2.gz ${openvswitch_source_directory}/${openvswitch_release_full}.tar.gz
    - unless: |
        [[ `stat -c %s ${openvswitch_source_directory}/${openvswitch_release_full}.tar2.gz` -eq `stat -c %s ${openvswitch_source_directory}/${openvswitch_release_full}.tar.gz`]] && echo 'files are equal'
    - cwd: ${home_directory}
    - require:
      - cmd: openvswitch-fixtar

#------------------
# Build the RPMS
#------------------

openvswitch-build-kernelrpm:
  cmd.run:
    - name: |
        rpmbuild -bb -D 'kversion `uname -r`' -D 'kflavors default' rhel/openvswitch-kmod-rhel6.spec
    - unless: |
        [[ `stat -c %s ${home_directory}/rpmbuild/RPMS/x86_64/kmod-${openvswitch_release_full}-1.el6.x86_64.rpm` -gt 1000000 ]] && echo 'rpm exists'
    - cwd: ${openvswitch_temp_directory}
    - require:
      - cmd: openvswitch-fixtar

openvswitch-build-baserpms:
  cmd.run:
    - name: |
        rpmbuild -bb rhel/openvswitch.spec
    - unless: |
        [[ `stat -c %s ${home_directory}/rpmbuild/RPMS/x86_64/${openvswitch_release_full}-1.x86_64.rpm` -gt 1000000 ]] && echo 'rpm exists'
    - cwd: ${openvswitch_temp_directory}
    - require:
      - cmd: openvswitch-download-source-tarball
      - cmd: openvswitch-download-temp-tarball

#------------------
# Install the RPMS
#------------------

openvswitch-kernel-pkg:
  pkg.installed:
    - name: kmod-openvswitch
    - sources:
      - kmod-openvswitch: '${home_directory}/rpmbuild/RPMS/x86_64/kmod-${openvswitch_release_full}-1.el6.x86_64.rpm'
    - require:
      - cmd: openvswitch-build-kernelrpm

openvswitch-userspace-pkg:
  pkg.installed:
    - name: openvswitch
    - sources:
      - openvswitch: '${home_directory}/rpmbuild/RPMS/x86_64/${openvswitch_release_full}-1.x86_64.rpm'
    - require:
      - pkg: openvswitch-kernel-pkg
      - cmd: openvswitch-build-baserpms

#--------------
# Build Notes
#--------------

# /root/rpmbuild/RPMS/x86_64/openvswitch-debuginfo-1.7.3-1.x86_64.rpm
# rpmbuild -bb -D 'kversion 2.6.32-279.el6.x86_64' -D 'kflavors default' rhel/openvswitch.spec
# [[ `stat -c %s /root/openvswitch.tar.gz` -eq 2153664 ]] || echo 'not equal'
# curl http://openvswitch.org/releases/openvswitch-1.7.3.tar.gz > /root/openvswitch-1.7.3.tar.gz
# curl http://openvswitch.org/releases/openvswitch-1.7.3.tar.gz > /root/rpmbuild/SOURCES/openvswitch-1.7.3.tar.gz

# gunzip rpmbuild/SOURCES/openvswitch-1.7.3.tar.gz
# tar -rf openvswitch-1.7.3.tar skbuff.h
# gzip openvswitch-1.7.3.tar

# less ~/openvswitch-1.7.3/datapath/linux/compat/include/linux/skbuff.h
# awk --posix '/static inline struct page \*skb_frag_page\(const skb_frag_t \*frag\)/, c++ == 3 {$0 = "//" $0} { print }' ~/openvswitch-1.7.3/datapath/linux/compat/include/linux/skbuff.h > ~/openvswitch-1.7.3/datapath/linux/compat/include/linux/skbuff.h_bak
# mv -f openvswitch-1.7.3/datapath/linux/compat/include/linux/skbuff.h_bak openvswitch-1.7.3/datapath/linux/compat/include/linux/skbuff.h
# tar -rf openvswitch-1.7.3.tar openvswitch-1.7.3/datapath/linux/compat/include/linux/skbuff.h
# gzip openvswitch-1.7.3.tar
# mv openvswitch-1.7.3.tar.gz /root/rpmbuild/SOURCES/

# rpm -ivh /root/rpmbuild/RPMS/x86_64/kmod-openvswitch-1.7.3-1.el6.x86_64.rpm

# /root/rpmbuild/BUILD/openvswitch-1.7.3/datapath/linux/compat/include/linux
# awk --posix '/static inline struct page \*skb_frag_page\(const skb_frag_t \*frag\)/, c++ == 3 {$0 = "//" $0} { print }' ./skbuff.h > temp.h
# rpmbuild -bb -D 'kversion 2.6.32-279.el6.x86_64' -D 'kflavors default' rhel/openvswitch-kmod-rhel6.spec

