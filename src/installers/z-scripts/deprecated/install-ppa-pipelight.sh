#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'pipelight' using the author's PPA repository
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
Pipelight is a special browser plugin which allows one to use Windows-only
plugins inside Linux browsers.  Pipelight currently focuses on Silverlight and
its features, such as playing DRM-protected videos.  The project requires a
patched version of Wine to execute the Silverlight DLL.

The Pipelight project combines the effort by Erich E. Hoover with a new browser
plugin that embeds Silverlight directly into any Linux browser that supports
the Netscape Plugin API.  He worked on a set of Wine patches to get Playready
DRM-protected content working inside Wine, and afterwards created an Ubuntu
package called 'netflix-desktop'.  This package allows one to use Silverlight
inside a Windows version of Firefox, which works as a temporary solution, but
is not really user-friendly, and moreover requires Wine to translate all API
calls of the browser.  Pipelight was created to solve this problem.

Pipelight consists out of two parts: A Linux library which is loaded into the
browser, and a Windows program started in Wine.  The Windows program, called
'pluginloader.exe', simply simulates a browser and loads the Silverlight DLLs.
When you open a page with a Silverlight application, the library will send all
commands from the browser through a pipe to the Windows process and act like a
bridge between your browser and Silverlight.  The pipes used do not have any
significant impact on the speed of the rendered video, since the video and
audio data are not send through the pipe.  Only the initialization parameters
and (some) network traffic is send through them.  As a user, you will likely
not notice anything and can simply use Silverlight the same way as on Windows.
"

SET_NAME="Pipelight"
PACKAGE_SET="pipelight-multi  ppa-purge  "

REPO_NAME="${SET_NAME} (PPA)"
REPO_URL="ppa:pipelight/stable"
REPO_GREP="pipelight.*stable.*${DISTRO}"

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

INST_VERS=$( wine --version 2>/dev/null | \
        egrep -o '[[:digit:]]+[.][[:digit:]]' )

if (( $? == 0 )); then

    Get_YesNo_Defaulted "n" \
"Wine version ${INST_VERS} is already installed.
Co-installing multiple versions of wine is not recommended.
Continue?"
fi

(( $? > 0 )) && exit

Get_YesNo_Defaulted "y" "Important: Have all browsers been closed?"
(( $? > 0 )) && ThrowError "${ERR_USAGE}" "${APP_SCRIPT}" \
        "Cannot install Pipelight if browsers are running !"

echo "
Note that this installation requires user input mid-way through to confirm
an End User License Agreement for installing font packages.  (Use the <tab>
key to jump between response fields, and <Enter> to select a response.)
"
sleep 3

QualifySudo

PerformAppInstallation "-r" "$@"

sudo pipelight-plugin --enable silverlight
sudo pipelight-plugin --enable widevine

InstallComplete
