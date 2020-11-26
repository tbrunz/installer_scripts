#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Fixup APT repository lists
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


##############################################################################
#
# Fix the APT repository 'source.list' to replace the default source repos
# with those for kernel.org.
#
Replace_Default_Repository_Sources() {

    local NEW_FILE_GLOB
    local NEWFILE
    local OLDFILE
    local INSTALL

    REPO_URL_DIR=../repo-urls
    PRECISE_URL_GLOB="precise"
    TRUSTY_URL_GLOB="trusty"
    VIVID_URL_GLOB="vivid"
    WILY_URL_GLOB="wily"
    XENIAL_URL_GLOB="xenial"
    YAKKITY_URL_GLOB="yakkity"
    ZESTY_URL_GLOB="zesty"
    ARTFUL_URL_GLOB="artful"
    BIONIC_URL_GLOB="bionic"
    COSMIC_URL_GLOB="cosmic"
    DISCO_URL_GLOB="disco"
    EOAN_URL_GLOB="eoan"
    FOCAL_URL_GLOB="focal"
    GROOVY_URL_GLOB="groovy"

    # There's no need to programatically edit the original file;
    # We'll just swap it out with a pre-configured file.
    #
    GetOSversion
    INSTALL=false

    if [[ ${RELEASE} =~ 12.04 ]]; then

        NEW_FILE_GLOB=${PRECISE_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 14.04 ]]; then

        NEW_FILE_GLOB=${TRUSTY_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 15.04 ]]; then

        NEW_FILE_GLOB=${VIVID_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 15.10 ]]; then

        NEW_FILE_GLOB=${WILY_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 16.04 ]]; then

        NEW_FILE_GLOB=${XENIAL_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 16.10 ]]; then

        NEW_FILE_GLOB=${YAKKITY_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 17.04 ]]; then

        NEW_FILE_GLOB=${ZESTY_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 17.10 ]]; then

        NEW_FILE_GLOB=${ARTFUL_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 18.04 ]]; then

        NEW_FILE_GLOB=${BIONIC_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 18.10 ]]; then

        NEW_FILE_GLOB=${COSMIC_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 19.04 ]]; then

        NEW_FILE_GLOB=${DISCO_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 19.10 ]]; then

        NEW_FILE_GLOB=${EOAN_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 20.04 ]]; then

        NEW_FILE_GLOB=${FOCAL_URL_GLOB}
        INSTALL=true

    elif [[ ${RELEASE} =~ 20.10 ]]; then

        NEW_FILE_GLOB=${GROOVY_URL_GLOB}
        INSTALL=true
    fi

    if [[ ${INSTALL} == true ]]; then

        ResolveGlobFilename "fullpath" \
            "${REPO_URL_DIR}/${NEW_FILE_GLOB}" 1 "${NEW_FILE_GLOB}*"

        NEWFILE=${FILE_LIST}

        RESULT=$( stat "${NEWFILE}" | grep 'Access: (' | \
                egrep -o '[-]([rwx-]{3}){3}' | \
                sed -re 's|[-]([rwx-]{3})([rwx-]{3}){2}|\1|' | \
            egrep -o [rwx-]{2} )

        if [[ "${RESULT}" == "rw" ]]; then

            OLDFILE=${APT_DIR}/${APT_SOURCES_FILE}

            copy "${OLDFILE}" "${OLDFILE}-orig"

            copy "${NEWFILE}" "${OLDFILE}"

            echo "Replaced the repo URLs file (${OLDFILE}) ... "
        else
            ThrowError "${ERR_FILEIO}" "${APP_SCRIPT}" \
                "Cannot access the '${NEWFILE}' file ! "
        fi
    else
        ThrowError "${ERR_WARNING}" "${APP_SCRIPT}" \
            "No alternate repository for distro '${DISTRO}' ! "
    fi
}

##############################################################################
#
# Fix the APT repository 'sources.list' to remove duplicate repo listings
# that are already in '.list' files kept in the 'sources.list.d' subdirectory.
#
Remove_Duplicate_Source_Lines_in_SubDir() {

    local REPO_URLS=()

    local REPO_URL

    # First, get a list of all repo source lines in the sources subdir,
    # then drop all blank and comment lines; Put the results into an array:
    #
    readarray -t REPO_URLS < <( cat ${APT_SOURCES_DIR}/*.list 2>/dev/null | \
        grep -v '^#' | grep -v '^[ \t]*$' )

    if (( $? > 0 || ${#REPO_URLS[@]} < 1 )); then

        if (( ${#REPO_URLS[@]} < 1 )); then
            echo "Cannot find any 3rd-party repo URLs ! "
        else
            echo "Cannot read the 3rd-party repo lists ! "
        fi
        return
    fi

    # Now search the main sources file for any of these source lines;
    # if found, blank the repo string.  (Note that any commented strings
    # will end up blank comments.)
    #
    for REPO_URL in "${REPO_URLS[@]}"; do

        sudo sed -r -i -e "s|${REPO_URL}||" "${APT_DIR}/${APT_SOURCES_FILE}"
    done
}

##############################################################################
#
# Edit the APT repository 'sources.list' to enable the Canonical Partners
#
Enable_Partners_in_Sources_List() {

    sudo sed -r -i -e "/deb http.*partner/ s/# //" \
        "${APT_DIR}/${APT_SOURCES_FILE}"
}

##############################################################################
#
# Fix the APT repository 'sources.list' to remove lines with duplicate repo
# phrases that are already present as part of another source line.
#
# For 'raring-backports multiverse', as there is already an entry present
# for 'raring-backports main restricted universe multiverse'.
#
Remove_Duplicate_Source_List_Phrases() {

    local DUPLICATE_PHRASES=(

        "raring-backports multiverse$"
    )

    local DUPED_PHRASE

    for DUPED_PHRASE in "${DUPLICATE_PHRASES[@]}"; do

        sudo sed -r -i -e "\|${DUPED_PHRASE}|{d}" \
            "${APT_DIR}/${APT_SOURCES_FILE}"
    done
}

##############################################################################
#
# Fix the APT repository 'sources.list' to remove lines with duplicate repo
# phrases that are already present as part of another source line.
#
# For 'raring-backports multiverse', as there is already an entry present
# for 'raring-backports main restricted universe multiverse'.
#
Relocate_Source_List_Phrases() {

    local CHROME_LIST="google-chrome.list"
    local GOOGLE_LIST="dl.google.com"
    local VBOX_LIST="virtualbox.org"
    local DOCKER_LIST="download.docker.com"
    local WINE_LIST="dl.winehq.org"

    local RELOCATE_PHRASES=(
        "${GOOGLE_LIST}"
        "${VBOX_LIST}"
        "${DOCKER_LIST}"
        "${WINE_LIST}"
    )

    local GREP_PHRASE

    for GREP_PHRASE in "${RELOCATE_PHRASES[@]}"; do

        RESULT=$( grep ${GREP_PHRASE} "${APT_DIR}"/"${APT_SOURCES_FILE}" )

        if [[ -n "${RESULT}" ]]; then

            APT_SRC_FILE=${GREP_PHRASE}-${DISTRO}.list

            QualifySudo
            sudo touch "${APT_SOURCES_DIR}"/"${APT_SRC_FILE}"

            printf "%s\n" "# Relocated from ${APT_DIR}/${APT_SOURCES_FILE} " \
                | sudo tee -a "${APT_SOURCES_DIR}"/"${APT_SRC_FILE}"

            printf "%s\n" "${RESULT}" \
                | sudo tee -a "${APT_SOURCES_DIR}"/"${APT_SRC_FILE}"
        fi
    done

    # Google does us the disfavor of adding its repo line to the Ubuntu
    # 'sources.list' file (bad enough!), but THEN doubles down by listing
    # it again in a 'chrome list' file in 'sources.list.d'  Fix this outrage...
    #
    RESULT=$( find "${APT_SOURCES_DIR}" -type f -iname "${CHROME_LIST}*" )
    [[ -z "$RESULT" ]] && return

    sudo rm -rf "${APT_SOURCES_DIR}"/"${CHROME_LIST}"*
}

##############################################################################
#
# Verify that the user has launched us using 'sudo'.
#
ls /root >/dev/null 2>&1

if (( $? != 0 )); then
    echo "${APP_SCRIPT}: Must run this script as 'root'. "
    exit 1
fi

GetOSversion
QualifySudo
Relocate_Source_List_Phrases
Remove_Duplicate_Source_List_Phrases
Remove_Duplicate_Source_Lines_in_SubDir
Replace_Default_Repository_Sources

##############################################################################
