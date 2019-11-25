#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install TrueType & other Linux fonts
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

MS_TT_CORE_FONTS=msttcorefonts
MS_CLEARTYPE_FONTS=mscleartypefonts
MS_TRUETYPE_FONTS=mstruetypefonts

PKG_MS_TTF_CORE_FONTS=msttcorefonts

TTF_DESTINATION_DIR=/usr/share/fonts/truetype
TTF_DEFOMA_DIR=/var/lib/defoma/x-ttcidfont-conf.d/dirs/TrueType


SET_NAME="fonts"
SOURCE_DIR="../fonts"
SOURCE_GLOB="ttf-mscorefonts*deb"

PACKAGE_SET="
%    *% fonts-roboto
%    *% t1-xfree86-nonfree
%    *% ttf-xfree86-nonfree
%    *% ttf-dejavu
%    *% ttf-bitstream-vera
%    * ttf-MS TT Core fonts %
%    * ttf-MS ClearType fonts %
%    * ttf-Misc MS TT fonts %
"

#
# Strip out (only) the individual '%' characters for usage display:
#
DISPLAY_SET=$( printf %s "${PACKAGE_SET}" | sed -e 's/%//g' )

USAGE="
This 'meta-package' installs a set of useful fonts
from cached packages and the Ubuntu repos:
${DISPLAY_SET}
"

: <<'__COMMENT'
echo "
Note that this installation requires user input mid-way through to confirm
an End User License Agreement for installing font packages.  (Use the <tab>
key to jump between response fields, and <Enter> to select a response.)
"
sleep 3
__COMMENT

#
# Ubuntu 18.04 (Bionic) has the 'ttf-mscorefonts-installer' v3.6 package
#
if (( MAJOR < 17 )); then

    ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}
    DEB_PACKAGE=${FILE_LIST}
fi

PACKAGE_SET="${PACKAGE_SET}  cabextract  "

PerformAppInstallation "-r" "$@"

#
# Function for installing each font file set (NOW OBSOLETE)
#
InstallFont() {
    FONT_NAME=${1}

    FindGlobFilename "basename" "${SOURCE_DIR}" 1 "${FONT_NAME}*"
    if (( $? > 0 )); then
        echo -n "Cannot find font package "
        echo    "'${SOURCE_DIR}/${FONT_NAME}', skipping... "
        return
    fi

    QualifySudo
    makdir "${TTF_DESTINATION_DIR}"

    # Jump into the directory and copy all the font files to the destination
    #
    chgdir "${SOURCE_DIR}"

    copy "${FONT_NAME}"* "${TTF_DESTINATION_DIR}"/
    sudo chmod 644 "${TTF_DESTINATION_DIR}"/${FONT_NAME}*

    echo "...installed font '${FONT_NAME}' "

    if [[ -d "${TTF_DEFOMA_DIR}" ]]; then

        chgdir "${TTF_DEFOMA_DIR}"

        sudo ln -f -s "${TTF_DESTINATION_DIR}"/"${FONT_NAME}"* .
        (( $RESULT > 0 )) && ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Cannot link the font files to '${TTF_DEFOMA_DIR}' !"
    fi
}

#
# Install fonts for which we have the individual font files:
#
echo
QualifySudo

for FONT_GROUP in \
        ${MS_TT_CORE_FONTS} ${MS_CLEARTYPE_FONTS} ${MS_TRUETYPE_FONTS}; do

    echo "Installing '${FONT_GROUP}' fonts... "

    # These next two directory paths must NOT have spaces in them !
    #
    FONT_GROUP_SOURCE_DIR=${SOURCE_DIR}/${FONT_GROUP}
    FONT_GROUP_DEST_DIR=${TTF_DESTINATION_DIR}/${FONT_GROUP}

    if [[ ! -d "${FONT_GROUP_SOURCE_DIR}" ]]; then
        echo -n "Cannot find font directory "
        echo    "'${FONT_GROUP_SOURCE_DIR}', skipping... "
        continue
    fi

    makdir "${FONT_GROUP_DEST_DIR}"
    (( $? > 0 )) && continue

    copy ${FONT_GROUP_SOURCE_DIR}/* ${FONT_GROUP_DEST_DIR}/
    sudo chmod 644 ${FONT_GROUP_DEST_DIR}/*

    fc-cache ${FONT_GROUP_DEST_DIR}
done

InstallComplete
