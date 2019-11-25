#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Lua and support libraries using the Ubuntu repository.
# ----------------------------------------------------------------------------
#

SUGGEST_VERSION=5.1

INCLUDES="core-install.bash"

if [[ -f "${INCLUDES}" ]]; then source "${INCLUDES}"
else
    echo -n "$( basename "${0}" ): error: "
    echo    "Could not source the '${INCLUDES}' file ! "
    exit
fi

GetScriptName "${0}"

SET_NAME="Lua"

USAGE="
Lua is a lightweight, multi-paradigm programming language designed primarily
for embedded systems and clients.  Lua is cross-platform, as the interpreter
is written in ANSI C, and has a relatively simple C API.

Lua was originally designed in 1993 as a language for extending software
applications to meet the increasing demand for customization at the time.
It provided the basic facilities of most procedural programming languages,
but more complicated or domain-specific features were not included; rather,
it included mechanisms for extending the language, allowing programmers to
implement such features.  As Lua was intended to be a general embeddable
extension language, the designers of Lua focused on improving its speed,
portability, extensibility, and ease-of-use in development.

This script installs the desired version from the Ubuntu repository.

http://www.lua.org/
http://lua-users.org
"

#
# Start with the assumption that the user doesn't provide a version;
# In this case, use the suggested version as a stand-in for 'usage':
#
PKG_VERSION=${SUGGEST_VERSION}

VERSION_MAJOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 1 )
VERSION_MINOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 2 )

PKG_VERSION=${VERSION_MAJOR}.${VERSION_MINOR}

#
# Invoked with the '-i' switch?  Or none at all?
#
if [[ -z "${1}" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# The user must tell us which Lua version they want to install,
# And must also include an 'update' switch (-n or -u)...
#
PKG_VERSION=${1}
shift

printf %s "${PKG_VERSION}" | \
        egrep '^[[:digit:]]+[.][[:digit:]]+$' >/dev/null

if (( $? != 0 )); then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation
fi

if [[ -z "${1}" || "${1}" == "-i" ]]; then
    PerformAppInstallation "$@"
    exit $?
fi

#
# At this point we have a desired version provided by the user;
# Use this 'X.Y' to determine the package names for the installation:
#
VERSION_MAJOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 1 )
VERSION_MINOR=$( printf "%s" "${PKG_VERSION}" | cut -d '.' -f 2 )

PKG_VERSION=${VERSION_MAJOR}.${VERSION_MINOR}

case ${PKG_VERSION} in
5.0 )
        LUA_PKG="lua50"
        LUA_DOC="lua50-doc"
        LUA_BIT=""
        CHECK=""
        ;;
5.1 )
        LUA_PKG="lua5.1"
        LUA_DOC="lua5.1-doc"
        LUA_BIT="lua-bit32"
        CHECK="lua-check  shake"
        ;;
5.2 )
        LUA_PKG="lua5.2"
        LUA_DOC="lua5.2-doc"
        LUA_BIT=""
        CHECK=""
        ;;
5.3 )
        LUA_PKG="lua5.3"
        LUA_DOC=""
        LUA_BIT=""
        CHECK=""
        ;;
* )

esac

PACKAGE_SET="${LUA_PKG}  ${LUA_DOC}  luajit  ${CHECK}
${LUA_BIT}  lua-cliargs  lua-filesystem  lua-json  lua-logging  lua-luassert
lua-penlight  lua-posix  lua-rings  lua-socket  lua-unit  "

PerformAppInstallation "$@"
