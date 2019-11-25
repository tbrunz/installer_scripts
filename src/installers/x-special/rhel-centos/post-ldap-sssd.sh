#!/bin/sh

# NOTE: add project name here:
$PROJECT="[project name goes here]"

# install sssd
/usr/bin/yum -y install sssd sssd-client sssd-client.i386 sssd-client.i686 sssd-tools nss-pam-ldapd

# copy cacert files
mkdir -p /etc/openldap/cacerts
curl -s ftp://linuxsupport.example.com/pub/work-ldap/certs/cacerts.tar.gz | tar xz cacerts/DigiCertHighAssuranceEVRootCA.pem -C /etc
cd /etc/openldap/cacerts
for cert in *.pem ; do ln -s $cert `openssl x509 -noout -hash -in $cert`.0 ; done

# switch to ldap/sssd auth
authconfig --enableshadow --enablemd5 --enablelocauthorize --enablepamaccess --enableldap --enableldapauth --ldapserver=ldap.example.com --ldapbasedn=ou=$PROJECT,ou=projects,dc=dir,dc=example,dc=com --enableldaptls --enablesssd --enablesssdauth --update

# modify access.conf
cat >> /etc/security/access.conf <<_EndAccess
+ : root : cron crond :0 tty1 tty2 tty3 tty4 tty5 tty6
# NOTE: configure netgroup(s) in the LDAP project for access, then add here (@users is just an example)
+ : @users : ALL
- : ALL : ALL
_EndAccess

# Increase entry_cache_timeout value
awk '/ldap_search_base/ && !x {print "entry_cache_timeout = 18000"; x=1} 1' /etc/sssd/sssd.conf > /tmp/sssd.conf-new && mv -f /tmp/sssd.conf-new /etc/sssd/sssd.conf
chmod 0600 /etc/sssd/sssd.conf

# Enable nscd for hosts caching only
/usr/bin/yum -y install nscd
/sbin/chkconfig nscd on
sed -e '/enable-cache.*passwd/s/yes/no/' -e '/enable-cache.*group/s/yes/no/' -e '/enable-cache.*services/s/yes/no/' -i.ksbak /etc/nscd.conf
