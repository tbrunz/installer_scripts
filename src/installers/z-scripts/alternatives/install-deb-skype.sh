#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Microsoft Skype from '.deb'
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
NOTE: This package installs Skype from the the latest '.deb' package.

Skype is a proprietary voice-over-IP service and software application owned
by Microsoft.  The service allows users to communicate with peers by voice
using a microphone, video by using a webcam, and instant messaging over the
Internet.  Phone calls may be placed to recipients on traditional telephone
networks.  Calls to other users within the Skype service are free of charge,
while calls to landline telephones and mobile phones are charged via a
debit-based user account system.

Skype has become popular for its additional features, including file transfer
and videoconferencing.  Competitors include SIP and H.323-based services,
such as Linphone, Ekiga, and Google Voice.

Unlike most other VoIP services, Skype is a hybrid peer-to-peer and client–
server system.  It makes use of background processing on computers running
Skype software.

Some network administrators have banned Skype on corporate, government, home,
and education networks, citing reasons such as inappropriate usage of
resources, excessive bandwidth usage, and security concerns.

The US intelligence agency, National Security Agency (NSA), can monitor Skype
user behavior (email, chat, uploads, downloads) through their surveillance
program PRISM.  Microsoft has admitted that it monitors Skype communications.

http://www.skype.com/intl/en-us/home
"

SET_NAME="Microsoft Skype (DEB)"
PACKAGE_SET="qt4-qtconfig
            gtk2-engines-murrine:i386  gtk2-engines-pixbuf:i386  "

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

GetOSversion

SOURCE_DIR="../skype"
SOURCE_GLOB="*4.3*deb"

ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
DEB_PACKAGE=${FILE_LIST}

QualifySudo
sudo dpkg --add-architecture i386

PerformAppInstallation "$@"
