#! /usr/bin/env bash
#

SCRIPT_FILE=${1}
TMP_FILE=${SCRIPT_FILE}.tmp

###############################################################################

GetYesNo () {
    unset REPLY

    until [[ "${REPLY}" == "y" || "${REPLY}" == "n" ]]; do

        read -e -r -p "${PROMPT}"

        if [[ -z "${REPLY}" ]]
        then
            REPLY=${DEFAULT}
        else
            REPLY=${REPLY:0:1}
            REPLY=${REPLY,,}
        fi
    done
}

###############################################################################

if (( $# < 1 )); then
    echo 1>&2 "usage: ${0} <script-file> "
    exit 1
fi

if [[ ! -e "${SCRIPT_FILE}" ]]; then
    echo 1>&2 "error: '${SCRIPT_FILE}' doesn't exist ! "
    exit 1
fi

if [[ ! -w "${SCRIPT_FILE}" ]]; then
    echo 1>&2 "error: '${SCRIPT_FILE}' is not a writable file ! "
    exit 1
fi

if [[ -e "${TMP_FILE}" ]]; then
    echo 1>&2 "error: '${TMP_FILE}' exists; can't overwrite ! "
    exit 1
fi


cat "${SCRIPT_FILE}" | \
sed -r -e '/^VERSION=/d' | \
sed -r -e '9,13d' | \
sed -r -e '2,4d' > "${TMP_FILE}"

echo
echo
diff -cs "${SCRIPT_FILE}" "${TMP_FILE}"
echo
echo

PROMPT="Okay to replace '${SCRIPT_FILE}'? [Y/n] "
DEFAULT='y'

GetYesNo 

if [[ "${REPLY}" == "n" ]]; then

    PROMPT="Keep '${TMP_FILE}'? [y/N] "
    DEFAULT='n'

    GetYesNo 
    [[ "${REPLY}" == "n" ]] && rm "${TMP_FILE}"

    echo "Nothing changed... "

else
    rm "${SCRIPT_FILE}"

    if (( $? != 0 )); then
        echo 1>&2 "error: could not remove '${SCRIPT_FILE}' ! "
        exit 1
    fi

    mv "${TMP_FILE}" "${SCRIPT_FILE}"

    if (( $? != 0 )); then
        echo 1>&2 "error: could not rename '${TMP_FILE}' to '${SCRIPT_FILE}' ! "
        exit 1
    fi

    echo "'${SCRIPT_FILE}' updated ! "
fi

###############################################################################


