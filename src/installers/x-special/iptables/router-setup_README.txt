
Install package 'iptables-persistent', which will install the 'iptables' and
'netfilter-persistent' packages.

Use 'make_iptables_rules_v4.sh' to generate a rules file.

When configuring a host for routing, don't forget to enable packet forwarding:

    # echo 1 > /proc/sys/net/ipv4/ip_forward

will temporarily enable this.  Make it a permanent setting by editing the file

    /etc/sysctl.conf

to add/enable a line containing

    net.ipv4.ip_forward=1

To enable the changes made in 'sysctl.conf', run the command

    sudo sysctl -p /etc/sysctl.conf

On RedHat based systems this is enabled when restarting the network service:

    service network restart

On Debian/Ubuntu systems, this can be done by restarting the 'procps' service:

    sudo service procps restart

===============================================================================
