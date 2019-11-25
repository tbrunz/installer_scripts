#! /bin/sh
# /etc/init.d/noip2.sh

### BEGIN INIT INFO
# Provides:          noip2
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts the No-IP DUC daemon
# Description:       This script turns the 'noip.com' Dynamic Update Client 
#                    into a Linux service (running in daemon mode)
### END INIT INFO

# Supplied by no-ip.com
# Modified for Debian GNU/Linux by Eivind L. Rygge
# Corrected 1-17-2004 by Alex Docauer
# Modified for Ubuntu GNU/Linux by Florian Moesch

# modify for your init-functions
. /lib/lsb/init-functions

DAEMON=/usr/local/bin/noip2
NAME=noip2

test -x ${DAEMON} || exit 0

case "$1" in
start)
    echo -n "Starting dynamic address update: "
    start-stop-daemon --start --exec ${DAEMON}
    echo "${NAME}."
    ;;
    
stop)
    echo -n "Shutting down dynamic address update:"
    start-stop-daemon --stop --oknodo --retry 30 --exec ${DAEMON}
    echo "${NAME}."
    ;;

restart)
    echo -n "Restarting dynamic address update: "
    start-stop-daemon --stop --oknodo --retry 30 --exec ${DAEMON}
    start-stop-daemon --start --exec ${DAEMON}
    echo "${NAME}."
    ;;

status)
    status_of_proc ${DAEMON} ${NAME} && exit 0 || exit $?
    ;;
    
*)
    echo "Usage: ${0} {status|start|stop|restart}"
    exit 1
esac

exit 0

