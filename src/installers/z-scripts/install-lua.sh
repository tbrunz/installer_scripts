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
SOURCE_DIR="../lua/"

#
# Determine which Lua versions exist with development packages
#
LUA_PKG_PREFIX="lua"
LUA_DEV_PREFIX="liblua"

LUAJIT_PKG_PREFIX="luajit"
LUAJIT_DEV_PREFIX="libluajit"

EXTRA_SCRIPT_DIR_PATH="/usr/local/bin"
LUA_VERSION_SCRIPT="luavers"

MANUAL_DIR_PATH="/usr/share/man/man1"
ETC_ALT_PRIORITY="100"

#
# Grep patterns
#
LUA_PKG_GREP="^${LUA_PKG_PREFIX}${X_Y_VERS_GREP}"
LUA_DEV_GREP="${LUA_DEV_PREFIX}${X_Y_VERS_GREP}(-[[:digit:]])?-dev"

LUAJIT_PKG_GREP="^${LUAJIT_PKG_PREFIX}${X_Y_VERS_GREP}"
LUAJIT_DEV_GREP="${LUAJIT_DEV_PREFIX}${X_Y_VERS_GREP}(-[[:digit:]])?-dev"

#
# Lua Interpreter
#
LUA_INTERPRETER_NAME="lua-interpreter"
LUA_INTERPRETER_BASE="lua"

LUA_INTERPRETER_PATH="/usr/bin/${LUA_INTERPRETER_BASE}"

LUA_INTERPRETER_MANUAL_NAME="lua-manual"
LUA_INTERPRETER_MANUAL_PATH="${MANUAL_DIR_PATH}/lua.1.gz"

#
# Lua Compiler
#
LUA_COMPILER_NAME="lua-compiler"
LUA_COMPILER_BASE="luac"

LUA_COMPILER_PATH="/usr/bin/${LUA_COMPILER_BASE}"

LUA_COMPILER_MANUAL_NAME="lua-compiler-manual"
LUA_COMPILER_MANUAL_PATH="${MANUAL_DIR_PATH}/luac.1.gz"

#
# Which versions are available in the repository?
#
CACHE_SEARCH=$( apt-cache search ${LUA_PKG_PREFIX} 2>&1 | \
   egrep -o "^${LUA_PKG_GREP}" )

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Repo search on '${LUA_PKG_PREFIX}' failed: ${CACHE_SEARCH} ! "

#
# Isolate the package names and sort by version number
#
LUA_REPO_PKG_LIST=$( printf "%s" "${CACHE_SEARCH}" | sort | uniq )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "No packages for '${LUA_PKG_PREFIX}' in the repository ! "

#
# Make a table of installable packages
#
LUA_PACKAGE_TABLE=()

for LUA_REPO_PKG in ${LUA_REPO_PKG_LIST}; do
  #
  # Isolate the version number for this install package:
  #
  LUA_VERSION=$( printf "%s" "${LUA_REPO_PKG}" | egrep -o "${X_Y_VERS_GREP}" )

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Failure parsing Lua version number in '${LUA_REPO_PKG}' ! "

  # Search the distro package repo for the corresponding 'dev' package,
  # if it exists.  Allow for the cases where it doesn't...
  #
  DEV_PKG_NAME="${LUA_DEV_PREFIX}.*${LUA_VERSION}.*-dev"

  CACHE_SEARCH=$( apt-cache search ${DEV_PKG_NAME} 2>&1 )

  # Then try to parse out a package; it is NOT an error if this fails,
  # since not all Lua verions come with a separate 'doc' package;
  # If this is one such case, the result will be an empty string.
  #
  DEV_REPO_PKG=$( printf "%s" "${CACHE_SEARCH}" | egrep -o ${LUA_DEV_GREP} )

  # Search the distro package repo for the corresponding 'doc' package,
  # if it exists.  Allow for the cases where it doesn't...
  #
  DOC_PKG_NAME="${LUA_PKG_PREFIX}${LUA_VERSION}-doc"

  CACHE_SEARCH=$( apt-cache search ${DOC_PKG_NAME} 2>&1 )

  # Then try to parse out a package; it is NOT an error if this fails,
  # since not all Lua verions come with a separate 'doc' package;
  # If this is one such case, the result will be an empty string.
  #
  LUADOC_REPO_PKG=$( printf "%s" "${CACHE_SEARCH}" | \
      egrep -o "^${DOC_PKG_NAME}" )

  # Assemble the table:
  #
  LUA_PACKAGE_TABLE+=( \
      "${LUA_VERSION}*${LUA_REPO_PKG}*${DEV_REPO_PKG}*${LUADOC_REPO_PKG}" )
done

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

This script installs all 5.x versions from the Ubuntu repository, (but not
version 5.0) and sets the alternative for 'lua' & 'luac' to the version
provided on the command line.  I.e., it does not just install the selected
version, it makes the selected version the default.  Active versions are
managed using the Debian Alternatives mechanism in '/etc/alternatives'.

http://www.lua.org/
http://lua-users.org
"

# Create a package installation list
#
PACKAGE_SET="luajit  "

for TABLE_ROW in "${LUA_PACKAGE_TABLE[@]}"; do
  #
  # Extract fields 2..4 (which are package names) from the table
  #
  PACKAGE_SET="${PACKAGE_SET}$(echo "${TABLE_ROW}" | \
    awk -F '*' '{ printf "%s  %s  %s  ", $2, $3, $4 }' )"
done

POST_INSTALL="
Installed packages = ${PACKAGE_SET}

You may want to install the LuaRocks package repository, and/or install some
LuaRocks/Ubuntu repository packages.  Some suggestions:

lua-bit32  lua-cliargs  lua-filesystem  lua-json  lua-logging  lua-luassert
lua-penlight  lua-posix  lua-rings  lua-socket  lua-unit  lua-check  shake
"

# Invoked with no parameters or the '-i' switch?
#
if [[ -z "${1}" || "${1}" == "-p" || "${1}" == "-i" ]]; then
    PKG_VERSION=${SUGGEST_VERSION}
    PerformAppInstallation "$@"
    exit $?
fi

# The user must tell us which version they want to be the default,
# And must also include an 'update' switch (-n or -u)...
#
PKG_VERSION=${1}
shift

# Check to see if the Package Version parameter is a version number:
#
printf "%s" "${PKG_VERSION}" | egrep "^${X_Y_VERS_GREP}$" &>/dev/null

if (( $? != 0 )); then
  PKG_VERSION=${SUGGEST_VERSION}
  PerformAppInstallation
fi

# Check to see if the requested default version exists:
#
printf "%s" "${LUA_REPO_PKG_LIST}" | grep -q "${PKG_VERSION}"

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Version ${PKG_VERSION} is not in the repository ! "

if [[ -z "${1}" || ${1} == "-p" || "${1}" == "-i" ]]; then
  PerformAppInstallation "$@"
  exit $?
fi

# Install all teh packages!!
#
PerformAppInstallation "-r" "$@"

#
# ::sigh::  The lua package maintainer screwed up:
# They forgot to create Debian Alternatives entries for Lua 5.3,
# Which means we need to test all & create any that are missing.
#
for LUA_REPO_PKG in ${LUA_REPO_PKG_LIST}; do
  #
  # Isolate the version number & installed package from the table
  #
  LUA_VERSION=$( printf "%s" "${LUA_REPO_PKG}" | egrep -o "${X_Y_VERS_GREP}" )

  # Create a Debian Alternative for this version, as needed,
  # ...first for the Lua interpreter application...
  #
  Update_App_Alts "${LUA_INTERPRETER_BASE}${LUA_VERSION}" \
    "${LUA_INTERPRETER_NAME}" "${LUA_INTERPRETER_PATH}" "${ETC_ALT_PRIORITY}" \
    "${LUA_INTERPRETER_BASE}${LUA_VERSION}" \
    "${LUA_INTERPRETER_MANUAL_NAME}" "${LUA_INTERPRETER_MANUAL_PATH}"

  # ...then for the Lua compiler application...
  #
  Update_App_Alts "${LUA_COMPILER_BASE}${LUA_VERSION}" \
    "${LUA_COMPILER_NAME}" "${LUA_COMPILER_PATH}" "${ETC_ALT_PRIORITY}" \
    "${LUA_COMPILER_BASE}${LUA_VERSION}" \
    "${LUA_COMPILER_MANUAL_NAME}" "${LUA_COMPILER_MANUAL_PATH}"

done

#
# Now use the Debian Alternatives feature to set the alternatives
# for 'lua' (lua-interpreter) and 'luac' (lua-compiler) to the
# desired default version (which is given as a script parameter):
#
Set_App_Alts "--quiet" "${LUA_INTERPRETER_NAME}" \
  "${LUA_INTERPRETER_BASE}${PKG_VERSION}"

Set_App_Alts "--quiet" "${LUA_COMPILER_NAME}" \
  "${LUA_COMPILER_BASE}${PKG_VERSION}"

#
# Copy the script to switch all versions in sync:
#
SOURCE_GLOB="lua*.sh"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

for EXTRA_SCRIPT_PATH in "${FILE_LIST[@]}"; do

  [[ -e "${EXTRA_SCRIPT_PATH}" ]] || ThrowError "${ERR_CMDFAIL}" \
    "${APP_SCRIPT}" "Cannot find script '${EXTRA_SCRIPT_PATH}' ! "

  EXTRA_SCRIPT_FILE=$( basename "${EXTRA_SCRIPT_PATH}" ".sh" )

  copy "${EXTRA_SCRIPT_PATH}" "${EXTRA_SCRIPT_DIR_PATH}/${EXTRA_SCRIPT_FILE}"

  SetDirPerms "${EXTRA_SCRIPT_DIR_PATH}/${EXTRA_SCRIPT_FILE}"
done

eval "${LUA_VERSION_SCRIPT}"

InstallComplete

############################################################################
