#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Unlock the root partition in a Developer Mode Chromebook
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

Exit_if_OS_is_not_ChromeOS "${APP_SCRIPT}"

echo
Get_YesNo_Defaulted -n \
        "This will disable Root FS Verification.. Continue?"

(( $? == 0 )) || exit 1

QualifySudo

sudo /usr/share/vboot/bin/make_dev_ssd.sh \
        --remove_rootfs_verification --partitions 2

echo "Be sure to re-run the hosts file install script "
echo "after each Chromebook OS update. "
