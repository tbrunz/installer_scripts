#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Check a package for its existence in the repos and its installation status
# ----------------------------------------------------------------------------
# 


for PACKAGE in "$@"; do

    TARGET_PACKAGE=$( apt-cache search "${PACKAGE}" | grep "^${PACKAGE}" )

    if [[ -z "${TARGET_PACKAGE}" ]]; then 

        echo "Package '${PACKAGE}' is not in any of the repositories. ***** "

    else

        INSTALLED_PACKAGE=$( apt-cache show "${PACKAGE}" 2>/dev/null \
                | grep '^Package:' )

        if [[ -z "${INSTALLED_PACKAGE}" ]]; then 

            echo "Package '${PACKAGE}' has a defective repository entry. "
        
        else    

            printf %s "${INSTALLED_PACKAGE}" | awk '{ print $2 }' | \
                    xargs dpkg -l 2>/dev/null 1>&2

            if (( $? > 0 )); then
                echo "Package '${PACKAGE}' exists, but is not installed. "
            else
                echo "'${PACKAGE}' is already installed. "
            fi
        fi
    fi
done

