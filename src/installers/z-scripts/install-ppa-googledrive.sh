#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'Ocamlfuse' driver to enable mounting Google Drive folders.
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

USAGE="
'google-drive-ocamlfuse' is a FUSE filesystem backed by Google Drive, written
in OCaml.  It lets you mount your Google Drive in Linux.

Features:
* Full read/write access to ordinary files and folders
* Read-only access to Google Docs/Sheets/Slides (exp. to configurable formats)
* Multiple account support
* Duplicate file handling
* Access to trash (the '.Trash' directory)

Usage:
The first time, you can run 'google-drive-ocamlfuse' without parameters:

    $ google-drive-ocamlfuse

This will create the default application directory ('~/.gdfuse/default'),
containing the configuration file 'config' (see the wiki page for more details
about configuration).  It will also start a web browser to obtain authorization
to access your Google Drive.  This will let you modify the default configuration
before mounting the filesystem.

Then you can mount the filesystem:

    $ google-drive-ocamlfuse <mountpoint>

If you have more than one account, you can run:

    $ google-drive-ocamlfuse -label <label> [<mountpoint>]

Using <label> to distinguish different accounts.  The program will use the
directory '~/.gdfuse/label' to host the configuration, application state, and
file cache.  No files are shared among different accounts, so you can have a
different configuration for each one.

To unmount the filesystem, issue this command:

    $ fusermount -u <mountpoint>

You can revoke access to Google Drive here:
    https://accounts.google.com/b/0/IssuedAuthSubTokens

For more information, including info on Google Drive authorization:
    https://github.com/astrada/google-drive-ocamlfuse
    https://github.com/astrada/google-drive-ocamlfuse/wiki/Authorization
"

POST_INSTALL=${USAGE}

SET_NAME="Google Drive"
PACKAGE_SET="google-drive-ocamlfuse  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:alessandro-strada/ppa"
REPO_GREP="alessandro.*strada.*${DISTRO}"

PerformAppInstallation "-r" "$@"

[[ ${1} == "-p" ]] && exit

InstallComplete
