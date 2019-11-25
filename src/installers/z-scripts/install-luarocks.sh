#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install LuaRocks, using a cached tarball
# ----------------------------------------------------------------------------
#

#
# Source our includes, get our script name, etc. -- The usual...
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

#
# Where in our system do we put things? (Directories will be created.)
#
SET_NAME="LuaRocks"

LUAROCKS_TARBALL_DIR_PATH="/opt/luarocks"

LUA_PREFIX="/usr/bin"
LUAROCKS_PREFIX="/usr/local"
LUAROCKS_BIN_PATH="${LUAROCKS_PREFIX}/bin"

ALT_PRIORITY_APP_NAME="lua-interpreter"
ALT_PRIORITY_APP_PREFIX="lua"
ALT_PRIORITY_DEFAULT="100"

EXTRA_SCRIPT_DIR_PATH="/usr/local/bin"
LUA_VERSION_SCRIPT="luavers"

LUAROCKS_APP_SCRIPT_NAME="luarocks"
LUAROCKS_ADMIN_SCRIPT_NAME="luarocks-admin"

LUAROCKS_APP_SCRIPT_PATH="${LUAROCKS_BIN_PATH}/${LUAROCKS_APP_SCRIPT_NAME}"
LUAROCKS_ADMIN_SCRIPT_PATH="${LUAROCKS_BIN_PATH}/${LUAROCKS_ADMIN_SCRIPT_NAME}"

#
# Determine which Lua versions exist with development packages
#
LUA_PKG_PREFIX="lua"
LUAJIT_PKG_PREFIX="luajit"

LUA_LIB_PREFIX="liblua"
LUAJIT_LIB_PREFIX="libluajit-"

LUA_APP_GREP="${LUA_PREFIX}/${LUA_PKG_PREFIX}${X_Y_VERS_GREP}"
LIB_DEV_GREP="${X_Y_VERS_GREP}[^[:alpha:]]+dev"

LUA_LIBDEV_GREP="^${LUA_LIB_PREFIX}${LIB_DEV_GREP}"
LUAJIT_LIBDEV_GREP="^${LUAJIT_LIB_PREFIX}${LIB_DEV_GREP}"

#
# Which version of Lua is the current version?
# (Note that installing LuaRocks requires that Lua already be installed.)
#
LUA_CURRENT_PATH=$( realpath "$( which lua 2>&1 )" 2>&1 )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "${SET_NAME} is dependent on Lua, which is not installed..?? "

LUA_CURRENT_VERSION=$( printf "%s" "${LUA_CURRENT_PATH}" | \
  egrep -o "${X_Y_VERS_GREP}" )

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Cannot determine a Lua version from '${LUA_CURRENT_PATH}' "

#
# Which versions are installed & have a development package available?
#
LUA_WHEREIS_LIST=( $( whereis lua ) )

for ITEM in "${LUA_WHEREIS_LIST[@]}"; do
   #
   # Grep out a path to a Lua app; there may be more than one installed.
   #
  LUA_APP_PATH=$( printf "%s" "${ITEM}" | egrep -o ${LUA_APP_GREP} )

  (( $? == 0 )) && LUA_APP_ARY+=( "${LUA_APP_PATH}" )
done

(( ${#LUA_APP_ARY[@]} > 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Cannot determine any installed Lua interpreter versions ! "

#
# Convert the array of app version paths into a string of paths,
# separated by newlines, then turn it into a sorted list of unique
# paths.  Use this list to make a table of installable packages:
#
LUA_APP_LIST=$( printf "%s\n" "${LUA_APP_ARY[@]}" | sort | uniq )

for LUA_APP in ${LUA_APP_LIST}; do
  #
  # Isolate the version number
  #
  LUA_VERSION=$( printf "%s" "${LUA_APP}" | egrep -o "${X_Y_VERS_GREP}" )

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Cannot determine version number of installed version '${LUA_APP}' ! "

  # See if this version has a development library package (required)
  #
  CACHE_SEARCH=$( apt-cache search "${LUA_LIB_PREFIX}${LUA_VERSION}" 2>&1 )

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Repo search on '${LUA_LIB_PREFIX}${LUA_VERSION}': ${CACHE_SEARCH}"

  # Check first to see if there is a dev package in the repo:
  #
  LUA_LIBDEV=$( printf "%s" "${CACHE_SEARCH}" | egrep -o "${LUA_LIBDEV_GREP}" )
  SEARCH_RESULT=$?

  # If so, check to see if it's installed:
  #
  dpkg -l | egrep -q "${LUA_LIBDEV}"
  SEARCH_RESULT=$(( $? + SEARCH_RESULT ))

  # Note that it is NOT an error if the lib-dev package can't be found;
  # it just means this version of Lua doesn't have a lib-dev package in
  # the repository, so we skip this version: No LuaRocks for you!
  #

  # If so, extract the package name and add a line to the table:
  #
  (( SEARCH_RESULT == 0 )) && \
    LUA_PACKAGE_TABLE+=( "${LUA_VERSION}*${LUA_APP}*${LUA_LIBDEV}" )
done

# Did anything make it through the sieve?
#
(( ${#LUA_PACKAGE_TABLE[@]} > 0 )) || \
   ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
      "No versions of Lua have a development package (required) installed ! "

#
# Create the usage prompt text:
#
USAGE="
Installs the LuaRocks package repository for the Lua language.

This script will scan for available Lua and LuaJit versions, install the
development packages that correspond to installed Lua verions, and build
the latest LuaRocks repository, as a LuaRock, for each.

Note that if you already have LuaRocks packages installed from the distro's
package repository, LuaRocks will not remove, modify, or replace them --
which could cause a conflict (especially as the distro's repo versions are
likely to be out of date; the 'lua-posix' distro package is known to prevent
this script from installing LuaRocks...)

https://luarocks.org/
https://luarocks.github.io/luarocks/releases/
https://github.com/luarocks/luarocks/wiki/Using-LuaRocks
https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Unix
"

POST_INSTALL="
You probably want to update 'luarocks' now (since it's been installed
from a cached tarball).

To update 'luarocks', run either 'luarupd' or 'luarocks install luarocks'.

This will fetch the latest version's install tarball from the project
repository; LuaRocks will then update itself.  (This works because this
script installs LuaRocks as a Lua Rock, rather than as an Ubuntu repo
package.  Distro packages will not be updated or replaced by LuaRocks.)

Install 'busted', the Lua unit testing framework, separately.
(Lua 'busted' will install many of the packages listed below.)

Some other suggested LuaRocks packages to install:
    compat52 / compat53 (be SURE to read the 'doc' output)
    bit32  luafilesystem  luasocket  *json*  lualogging
    lua_cliargs  luassert  penlight  rings  luaunit  luacheck
    luaposix  std._debug  std.normalize

To locate a Lua rock, enter 'luarocks search <pattern>'.
To get info on a Lua rock, enter 'luarocks doc <rockname>'.
To install a Lua rock, enter 'luari <rockname>'.
"

#
# Invoked with no parameters or the '-i' switch?
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# To continue, we require the 'unzip' package and
# one or more of the Lua development libraries:
#
PACKAGE_SET="build-essential  zip  unzip  lua-sec"

for LUA_PACKAGE_ROW in "${LUA_PACKAGE_TABLE[@]}"; do
  #
  # Snip off the lib-dev package name from this version's row in the table:
  #
  DEV_PACKAGE=$( printf "%s\n" "${LUA_PACKAGE_ROW}" | cut -d '*' -f 3 )

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Failure parsing development package from version table ! "

  PACKAGE_SET="${PACKAGE_SET}  ${DEV_PACKAGE}"
done

#
# Install all teh packages!
#
PerformAppInstallation "-r" "$@"

#
# Copy the script to switch all versions in sync:
#
SOURCE_DIR="../lua/"
SOURCE_GLOB="lua*.sh"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

for EXTRA_SCRIPT_PATH in "${FILE_LIST[@]}"; do

  [[ -e "${EXTRA_SCRIPT_PATH}" ]] || ThrowError "${ERR_CMDFAIL}" \
    "${APP_SCRIPT}" "Cannot find script '${EXTRA_SCRIPT_PATH}' ! "

  EXTRA_SCRIPT_FILE=$( basename "${EXTRA_SCRIPT_PATH}" ".sh" )

  copy "${EXTRA_SCRIPT_PATH}" "${EXTRA_SCRIPT_DIR_PATH}/${EXTRA_SCRIPT_FILE}"

  SetDirPerms "${EXTRA_SCRIPT_DIR_PATH}/${EXTRA_SCRIPT_FILE}"
done

#
# Find and unpack the LuaRocks tarball
#
SOURCE_DIR="../lua/luarocks"

SOURCE_SUFFIX=".tar.gz"
SOURCE_GLOB="luarocks-*${SOURCE_SUFFIX}"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
LUAROCKS_INSTALL_PKG_PATH=${FILE_LIST}

LUAROCKS_INSTALL_PKG=$( basename ${LUAROCKS_INSTALL_PKG_PATH} )
LUAROCKS_INSTALL_DIR=$( basename "${LUAROCKS_INSTALL_PKG}" "${SOURCE_SUFFIX}" )

# Create a directory (default: /opt/luarocks) to hold the tarballs and
# their unpacked directories; We need to build LuaRocks from source, here:
#
QualifySudo
makdir "${LUAROCKS_TARBALL_DIR_PATH}"

# Copy the tarball from our repo cache to this location, then untar;
# We don't untar directly from our repo because we want to leave the
# installer tarball behind on the target system (to allow re-installs).
#
copy "${LUAROCKS_INSTALL_PKG_PATH}" "${LUAROCKS_TARBALL_DIR_PATH}"/

cd "${LUAROCKS_TARBALL_DIR_PATH}" || \
  ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Failure to change directory to '${LUAROCKS_INSTALL_DIR}' ! "

(( $? == 0 )) || ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
  "Could not change directory to '${LUAROCKS_TARBALL_DIR_PATH}' ! "

# Once the tarball has been copied over, look for a previous directory
# from an earlier untarring of the same file; If found, delete it.
#
[[ -d "${LUAROCKS_INSTALL_DIR}" ]] && sudo rm -rf "${LUAROCKS_INSTALL_DIR}"

# Now untar the LuaRocks install tarball, to directory in this same location:
#
tar_zip "gz" "${LUAROCKS_INSTALL_PKG}"

# 'cd' to the unpacked tarball directory, and build one version for each
# version of Lua on our system (that also has a lib-dev package installed):
#
cd "${LUAROCKS_INSTALL_DIR}" || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Failure to change directory to '${LUAROCKS_INSTALL_DIR}' ! "

for LUA_PACKAGE_ROW in "${LUA_PACKAGE_TABLE[@]}"; do

  LUA_VERSION=$( printf "%s\n" "${LUA_PACKAGE_ROW}" | cut -d '*' -f 1 )

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Failure parsing Lua version number from version table ! "

  # Determine the Priority of the corresponding Lua Interpreter,
  # and use that as our priority.
  #
  APP_ALT_PRIORITY=${ALT_PRIORITY_DEFAULT}

  RESULT=$( Find_App_Alt_Priority "${ALT_PRIORITY_APP_NAME}" \
    "${ALT_PRIORITY_APP_PREFIX}${LUA_VERSION}" )

  (( $? == 0 )) && APP_ALT_PRIORITY=${RESULT}

  # We need to remove any pre-existing LuaRocks scripts from the 'bin'
  # directory, otherwise the installer will get confused and start making
  # these annoying sets of <filename>~~~~~~~ ad nauseum.  Oy!
  #
  sudo rm -rf "${LUAROCKS_APP_SCRIPT_PATH}"
  sudo rm -rf "${LUAROCKS_ADMIN_SCRIPT_PATH}"

  # Here's the payoff: Run .configure and then make:
  #
  sudo ./configure \
    --prefix="${LUAROCKS_PREFIX}" --lua-version="${LUA_VERSION}"

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Failure attempting to configure LuaRocks for Lua ${LUA_VERSION} ! "

  # Now make the 'bootstrap' version of LuaRocks:
  #
  sudo -H make bootstrap

  (( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
    "Failure attempting to make LuaRocks bootstrap for Lua ${LUA_VERSION} ! "

  # Change each hard-coded script that make creates into a versioned
  # script; We will use Debian Alternatives to manage these, just as
  # the Lua interpreter & compiler versions are managed.
  #
  Move_File_with_Backup "${LUAROCKS_APP_SCRIPT_PATH}" \
    "${LUAROCKS_APP_SCRIPT_PATH}${LUA_VERSION}"

  # Need to do the same for the 'luarocks-admin' file:
  #
  Move_File_with_Backup "${LUAROCKS_ADMIN_SCRIPT_PATH}" \
    "${LUAROCKS_ADMIN_SCRIPT_PATH}${LUA_VERSION}"

  # Now create the '/etc/alternatives' database entry for this version:
  #
  Update_App_Alts "${LUAROCKS_APP_SCRIPT_NAME}${LUA_VERSION}" \
    "${LUAROCKS_APP_SCRIPT_NAME}" "${LUAROCKS_APP_SCRIPT_PATH}" \
    "${APP_ALT_PRIORITY}"\
    "${LUAROCKS_ADMIN_SCRIPT_NAME}${LUA_VERSION}" \
    "${LUAROCKS_ADMIN_SCRIPT_NAME}" "${LUAROCKS_ADMIN_SCRIPT_PATH}"

done

#
# Now that all the version-specific LuaRocks packages are installed,
# set up the '/etc/alternatives' to point to the version that matches
# the current version of Lua on our system:
#
LUA_CURRENT_APP=$( basename "${LUA_CURRENT_PATH}" )

(( $? == 0 )) || ThrowError "${ERR_CMDFAIL}" "${APP_SCRIPT}" \
  "Could not resolve the filename for '${LUA_CURRENT_PATH}' ! "

LUA_CURRENT_VERSION=$( printf "%s" "${LUA_CURRENT_APP}" | \
  egrep -o "${X_Y_VERS_GREP}")

(( $? == 0 )) || ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
  "Could not resolve the file version for '${LUA_CURRENT_PATH}' ! "

# Call 'update-alternatives' to configure the matching version:
#
Set_App_Alts "--quiet" "${LUAROCKS_APP_SCRIPT_NAME}" \
  "${LUAROCKS_APP_SCRIPT_NAME}${LUA_CURRENT_VERSION}"

eval "${LUA_VERSION_SCRIPT}"

InstallComplete

############################################################################

: << __CONFIGURE_SCRIPT

$ ./configure -h
Usage: ./configure [OPTION]... [VAR=VALUE]...

To assign environment variables (e.g., CC, CFLAGS...), specify them as
VAR=VALUE.  See below for descriptions of some of the useful variables.

Defaults for the options are specified in brackets.

Configuration:
  -h, --help                   display this help and exit

Installation directories:
  --prefix=PREFIX              Directory where LuaRocks should be installed
                               [/usr/local]

By default, `make install' will install all the files in `/usr/local',
`/usr/local/lib' etc.  You can specify an installation prefix other than
`/usr/local/' using `--prefix', for instance `--prefix=$HOME'.

For better control, use the options below.

Fine tuning of the installation directories:
  --sysconfdir=SYSCONFDIR      Directory for single-machine config [PREFIX/etc]

Where to install files provided by rocks:
  --rocks-tree=DIR             Root of the local tree of installed rocks.
                               To make files installed in this location
                               accessible to Lua and your $PATH, see
                               "luarocks path --help" after installation.
                               Avoid using paths controlled by your
                               system's package manager, such as /usr.
                               - Default is [PREFIX]

Where is your Lua interpreter:
  --lua-version=VERSION        Use specific Lua version: 5.1, 5.2, 5.3, or 5.4
                               - Default is auto-detected.
  --with-lua-bin=LUA_BINDIR    Location of your Lua binar(y/ies).
                               - Default is the directory of the
                               auto-detected Lua interpreter,
                               (or DIR/bin if --with-lua is used)
  --with-lua=LUA_DIR           Use Lua from given directory. [LUA_BINDIR/..]
  --with-lua-include=DIR       Lua's includes dir. [LUA_DIR/include]
  --with-lua-lib=DIR           Lua's libraries dir. [LUA_DIR/lib]
  --with-lua-interpreter=NAME  Lua interpreter name.
                               - Default is to auto-detected

For specialized uses of LuaRocks:
  --force-config               Force using a single config location.
                               Do not honor the $LUAROCKS_CONFIG_5_x
                               or $LUAROCKS_CONFIG environment
                               variable or the user's local config.
                               Useful to avoid conflicts when LuaRocks
                               is embedded within an application.
  --disable-incdir-check       If you do not wish to use "luarocks build",
                               (e.g. when only deploying binary packages)
                               you do not need lua.h installed. This flag
                               skips the check for lua.h in "configure".

__CONFIGURE_SCRIPT
