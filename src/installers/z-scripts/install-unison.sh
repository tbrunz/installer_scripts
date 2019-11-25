#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Unison file synchronization application
# ----------------------------------------------------------------------------
# 

INCLUDES="core-install.bash" 

if [[ -f "${INCLUDES}" ]]; then source "${INCLUDES}" 
else 
    echo -n "$( basename "${0}" ): error: " 
    echo    "Could not source the '${INCLUDES}' file ! " 
    exit 
fi 

GetScriptName "${0}"

USAGE="
FINISH ME!!

Unison is an file-synchronization tool for *nix and Windows.  It allows two 
replicas of a collection of files and directories to be stored on different 
hosts (or different disks on the same host), modified separately, and then 
brought up to date by propagating the changes in each replica to the other.

Unison shares a number of features with tools such as configuration management 
packages (Subversion, PRCS, BitKeeper, etc.), distributed filesystems (Coda, 
etc.), uni-directional mirroring utilities ('rsync', etc.), and other 
synchronizers (Intellisync, Reconcile, etc).  However, there are several 
points where it differs:

* Unison runs on both Windows and many flavors of *nix (Solaris, Linux, OS X, 
etc.) systems.  Moreover, Unison works across platforms, allowing you to sync 
a Windows laptop with a Linix server, for example.

* Unlike simple mirroring or backup utilities, Unison can deal with updates 
to both replicas of a distributed directory structure.  Updates that do not 
conflict are propagated automatically.  Conflicting updates are detected and 
displayed.

* Unlike a distributed filesystem, Unison is a user-level program: there is 
no need to modify the kernel or to have superuser privileges on either host.

* Unison works between any pair of machines visible to each other on a network, 
communicating over either a direct socket link or tunneling over an encrypted 
SSH connection.  It is careful with network bandwidth, and runs well over slow 
links such as PPP connections.  Transfers of small updates to large files are 
optimized using a compression protocol similar to that used by 'rsync'.

* Unison is resilient to failure: It is careful to leave the replicas and its 
own data structures in a sensible state at all times, even in case of abnormal 
termination or communication failures.

* Unison is free; full source code is available under the GNU Public License. 

http://www.cis.upenn.edu/~bcpierce/unison/
"

SET_NAME="Unison"
PACKAGE_SET=""

PerformAppInstallation "$@"

