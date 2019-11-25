#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Java (latest in repo, or by version number)
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

GetOSversion

if (( MAJOR < 16 ))
then DEFAULT_VERSION=7
elif (( MAJOR == 16 ))
then DEFAULT_VERSION=8
elif [[ "${FLAVOR}" == "chromeos" ]]
then DEFAULT_VERSION=8
else DEFAULT_VERSION=9
fi

USAGE="
For Ubuntu 16.04+, installs the current version of Java (Java 8 for 16.04).
For Ubuntu 14.04, installs the Java 6 or 7 versions of the 'icedtea' plugin &
the Java Runtime Environment (JRE), or the full Oracle Java 8 JDK package.

The JRE provides the libraries, the Java Virtual Machine, and other components
needed to run applets and applications written in Java.  Two key deployment
technologies are part of the JRE: Java Plug-in, which enables applets to run in
popular web browsers; and Java Web Start, which deploys stand-alone applications
over a network.

Note: Installing Java 8 in Ubuntu 14.04 will require a PPA installation (from
WebUpd8), and will install the full Oracle JDK8 package, not just the JRE.

http://java.com/en/
http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html
"

SET_NAME="Java"
#
# The user must tell us which Java version they want to install,
# And must also include the 'update' switch...
#
unset BAIL_OUT
PKG_VERSION=${1}

printf "%s" "${PKG_VERSION}" | egrep '^[[:digit:]]+$' >/dev/null
RESULT=$?

if (( RESULT == 0 )); then
    shift
else
    PKG_VERSION=${DEFAULT_VERSION}
fi

[[ -z "${1}" || "${1}" == "-i" ]] && BAIL_OUT=true

[[ "${1}" != "-n" && "${1}" != "-u" ]] && BAIL_OUT=true

if [[ "${FLAVOR}" == "chromeos" ]]; then

    PACKAGE_SET="openjdk-8-jre"

elif (( MAJOR < 16 )); then

    case ${PKG_VERSION} in
    6)
        PACKAGE_SET="icedtea-6-plugin openjdk-6-jre  "
        ;;
    7)
        PACKAGE_SET="icedtea-7-plugin openjdk-7-jre  "
        ;;
    8)
        PACKAGE_SET="oracle-java8-installer  "

        REPO_NAME="${SET_NAME} (PPA)"
        REPO_URL="ppa:webupd8team/java"
        REPO_GREP="webupd8team.*java.*${DISTRO}"

        echo "
        Note that this installation requires user input mid-way through to
        confirm an End User License Agreement for installing the package.
        (Use the <tab> key to jump between response fields, and <Enter> to
        select a response.)
        "
        sleep 3
        ;;
    *)
        BAIL_OUT=true
        ;;
    esac
else
    case ${PKG_VERSION} in
    6 | 7)
        echo "
        Java ${PKG_VERSION} is not supported in Ubuntu ${MAJOR}.${MINOR}.
        You will need an Ubuntu 14.04 system to run this version.
        "
        exit
        ;;
    8)
        PACKAGE_SET="icedtea-8-plugin openjdk-8-jre  "
        ;;
    9)
        PACKAGE_SET="icedtea-8-plugin openjdk-9-jre  "
        ;;
    11)
        PACKAGE_SET="icedtea-8-plugin openjdk-11-jre  "
        ;;
    *)
        BAIL_OUT=true
        ;;
    esac
fi

if [[ ${BAIL_OUT} ]]; then

    PKG_VERSION=${DEFAULT_VERSION}
    PerformAppInstallation
fi

PerformAppInstallation "$@"
