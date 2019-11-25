#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install performance testing tools
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

SET_NAME="performance testing"
SOURCE_DIR="../perf-test"
PACKAGE_SET="
    %* glxgears              (Video benchmarking)%
    %* glxspheres            (Video benchmarking)%
    %* %hardinfo%              (System benchmarking)%
    %* %gtkperf%               (GTK+ performance benchmark)%
    %* %phoronix-test-suite%   (Phoronix Tests)%
"

GetOSversion
if [[ ${ARCH} == "x86_64" ]]; then

    SOURCE_GLOB="virtualgl*amd*"
else
    SOURCE_GLOB="virtualgl*386*"
fi

if [[ -n "${1}" ]]; then
    ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
    DEB_PACKAGE=${FILE_LIST}
fi

#
# Strip out (only) the individual '%' characters for usage display:
#
DISPLAY_SET=$( printf %s "${PACKAGE_SET}" | sed -e 's/%//g' )

USAGE="
This package installs performance testing tools:
${DISPLAY_SET}
"

POST_INSTALL="
    To run 'glxgears', enter 'glxgears' in a terminal.

    To run 'glxspheres', enter '/opt/VirtualGL/bin/glxspheres64' in a terminal.

    To run 'Hardinfo', 'GTKperf', or 'Phoronix Test Suite', search for them
    in the Dash -- the first two are GUI-based; Phoronix runs from a terminal
    window that will open.
"

PACKAGE_SET="mesa-utils  ${PACKAGE_SET}"

PerformAppInstallation "$@"
