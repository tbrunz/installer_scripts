#!/bin/sh

##########################################################
### Script: post-centos.sh                             ###
### Post-install script for CentOS systems.            ###
##########################################################

### Determine CentOS release version ###
ELVERSION=`rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)`

### Add EPEL yum repository ###
/usr/bin/yum -y --nogpgcheck install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${ELVERSION}.noarch.rpm

### Install banner/motd files  ###
cat > /etd/motd <<_EndMotd
****************************************************************************
*                                                                          *
*   This computer is funded by the United States Government and operated   *
*   by the California Institute of Technology in support of ongoing        *
*   U.S. Government programs and activities.  If you are not authorized    *
*   access to this system, disconnect now.  Users of this system have no   *
*   expectation of privacy.  By continuing, you consent to your keystrokes *
*   and data content being monitored.                                      *
*                                                                          *
****************************************************************************
_EndMotd
cp -a /etc/motd /etc/ssh/banner
sed -e 's/^#Banner.*$/Banner \/etc\/ssh\/banner/' -i.ksbak /etc/ssh/sshd_config

### Install default iptables rules (allow ssh, bigfix, security, admin hosts) ###
# NOTE: commands would go here to retrieve a standard iptables file from some admin host and write it to /etc/sysconfig/iptables
if [ $ELVERSION -eq 5 -o $ELVERSION -eq 6 ] ; then
    /sbin/chkconfig iptables on
elif [ $ELVERSION -eq 7 ] ; then
    # Disable firewalld; switch to legacy iptables service
    /usr/bin/yum -y install iptables-services
    /usr/bin/systemctl mask firewalld.service
    /usr/bin/systemctl disable dbus-org.fedoraproject.FirewallD1.service
    /usr/bin/systemctl enable iptables.service
fi

### Configure ntpd ###
yum -y install ntpdate ntp
sed -e 's/^server/#server/g' -i.ksbak /etc/ntp.conf
ntpserver=`route -n | grep '^0.0.0.0' | awk '{print $2}'`
cat >> /etc/ntp.conf <<_EndNtp
server $ntpserver
restrict $ntpserver mask 255.255.255.255 nomodify notrap noquery
_EndNtp
echo "$ntpserver" > /etc/ntp/step-tickers
cp -f /etc/ntp/step-tickers /etc/ntp/ntpservers
if [ $ELVERSION -eq 5 -o $ELVERSION -eq 6 ] ; then
    /sbin/chkconfig ntpdate on
    /sbin/chkconfig ntpd on
elif [ $ELVERSION -eq 7 ] ; then
    /usr/bin/systemctl disable chronyd.service
    /usr/bin/systemctl enable ntpd.service
    /usr/bin/systemctl enable ntpdate.service
fi

### Enable rc.local usage for CentOS 7 ###
if [ $ELVERSION -eq 7 ] ; then
    chmod +x /etc/rc.d/rc.local
fi

### Send syslog to syslog server ###
if [ -d /etc/rsyslog.d ] ; then
  syslogfile=/etc/rsyslog.d/my-syslog.conf
else
  syslogfile=/etc/syslog.conf
fi
cat >> $syslogfile <<_EndSyslog
#
# Syslog Server
kern.emerg;auth.info;authpriv.info;daemon.notice        @mysyslog.example.com
_EndSyslog

### Install BigFix ###
# NOTE: The following line assumes BESAgent is in a configured yum repository, which it will not be by default.
#       The package can also be placed in a standard local file path or shared from an admin host to install from there.
#       Latest packages available from from http://support.bigfix.com/bes/release/
/usr/bin/yum -y install BESAgent
mkdir -p /etc/opt/BESClient/
cd /etc/opt/BESClient
/usr/bin/wget -q http://bf1.example.com:52311/masthead/masthead.afxm
mv masthead.afxm actionsite.afxm
chmod 644 actionsite.afxm

### Modify password defaults to comply with security rules ###
sed -e 's/^PASS_MAX_DAYS.*$/PASS_MAX_DAYS 90/' -e 's/^PASS_MIN_LEN.*$/PASS_MIN_LEN  8/' -i.ksbak /etc/login.defs
sed -e 's/^password.*requisite.*$/password    requisite     pam_cracklib.so try_first_pass retry=3 type=LINUX minlen=8 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1/' -e 's/^password.*sufficient.*pam_unix.so.*$/password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok remember=10/' -i.ksbak /etc/pam.d/system-auth-ac

### Deny root login via ssh ###
sed -e "s/#PermitRootLogin.*/PermitRootLogin no/" -i /etc/ssh/sshd_config

### Disable arcfour ciphers in OpenSSH to address SPL tickets ###
if [ $ELVERSION -eq 5 -o $ELVERSION -eq 6 ] ; then
    CIPHERS="aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,blowfish-cbc,cast128-cbc,aes192-cbc,aes256-cbc,rijndael-cbc@lysator.liu.se"
elif [ $ELVERSION -eq 7 ] ; then
    CIPHERS="aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes128-cbc,3des-cbc,blowfish-cbc,cast128-cbc,aes192-cbc,aes256-cbc,rijndael-cbc@lysator.liu.se"
else
    echo "CentOS Release not found"
fi
if [ -n "$CIPHERS" ] ; then
cat >> /etc/ssh/sshd_config <<_EndSSHDConfig
#
# Disable arcfour ciphers
Ciphers $CIPHERS
_EndSSHDConfig
fi

### Add SA sudoers permissions ###
# NOTE: the following assumes an "sa" POSIX group is defined
cat >> /etc/sudoers <<_EndSudoers
#
#################
### Send mail ###
#################
Defaults        mailto="root@localhost"
Defaults        mail_always
#
#############
### Users ###
#############
#
#
######################
### SA Permissions ###
######################
User_Alias	SA = %sa
SA		ALL = (ALL) ALL
Defaults:SA	!mail_always
Defaults:SA	!lecture
_EndSudoers

### Send root mail to admin list ###
# NOTE: configure email address on next line for root mail (preferably a list address)
echo "root:             [list address]@example.com" >> /etc/aliases
/usr/bin/newaliases

### Make magic SysRq keys work ###
if [ $ELVERSION -eq 5 -o $ELVERSION -eq 6 ] ; then
    sed -e 's/^kernel\.sysrq.*$/kernel.sysrq = 1/' -i.ksbak /etc/sysctl.conf
elif [ $ELVERSION -eq 7 ] ; then
    echo "kernel.sysrq = 1" >> /etc/sysctl.d/sysrq.conf
fi

### Show grub menu; verbose boot; no gui crappage ###
if [ $ELVERSION -eq 5 -o $ELVERSION -eq 6 ] ; then
    sed -e 's/^splashimage/#splashimage/' -e 's/^hiddenmenu/#hiddenmenu/' -e 's/ rhgb//' -e 's/ quiet//' -i.ksbak /boot/grub/grub.conf
elif [ $ELVERSION -eq 7 ] ; then
    sed -e 's/ rhgb//' -e 's/ quiet//' -i.ksbak /etc/default/grub
    /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
fi

### Change logrotate to save logs for 90 days; compress logs ###
sed -e 's/^rotate 4/rotate 13/g' -e 's/^#compress/compress/g' -i.ksbak /etc/logrotate.conf

### Install ncdu (NCurses Disk Usage) ###
/usr/bin/yum -y install ncdu

### Install colordiff ###
/usr/bin/yum -y install colordiff

### Install vim-enhanced ###
/usr/bin/yum -y install vim-enhanced

### Install atop htop, iftop, lshw, inxi ###
/usr/bin/yum -y install atop htop iftop lshw inxi
