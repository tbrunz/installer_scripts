#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Postfix mail server & configure
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

POSTFIX_DIR=/etc/postfix
POSTFIX_CONFIG_FILE=main.cf

MAIL_ALIASES_DIR=/etc
MAIL_ALIASES_FILE=aliases

SET_NAME="Postfix"
PACKAGE_SET="postfix  mailutils  "

USAGE="
${SET_NAME} is an MTA (Mail Transfer Agent), an application used to send and
receive email.  This script will install and configure ${SET_NAME} so that it
can be used to send emails by local applications only –- that is, those
apps installed on the same server that Postfix is installed on.

Why would you want to do that?  If you're already using a third-party email
provider for sending and receiving emails, you of course do not need to run
your own mail server.  However, if you have applications that need to send
email notifications, running a local SMTP server configured for 'send-only'
is a good alternative to using a third-party email service provider or
running a full-blown SMTP server.

An example of an application that sends email notifications is 'mdadm',
which will send email alerts to any configured email address.  Though
'mdadm' or any other application of its kind can use a third-party email
provider's SMTP server to send email alerts, it can also use a local
(send-only) SMTP server.

You will need to have a valid domain name, like 'example.com', pointing to
your host.  (Services such as 'noip.com' are good for this.)
"

POST_INSTALL="
Test installation by entering

    echo \"This is a test\" | mail -s \"Test for ${SET_NAME}\" <email addr>
or
    sudo mdadm --monitor --scan --test --oneshot

which can be used to test both ${SET_NAME} and RAID array failure reporting.
"

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

echo
echo "Select 'Internet site' as the 'General type of config' when prompted. "
echo
echo "Set the FQDN using, e.g., '<location>.ddns.net' when prompted. "
echo

unset TARGET_EMAIL_ADDRESS
while [[ ! ${TARGET_EMAIL_ADDRESS} ]]; do

    read -e -r -p "Please enter the target email address: " TARGET_EMAIL_ADDRESS

    printf %s "${TARGET_EMAIL_ADDRESS}" | egrep -q '.+@.+[.].+'

    if (( $? > 0 )); then
        echo
        echo "Bad address... Try again. "
        unset TARGET_EMAIL_ADDRESS
    fi
done

echo
PerformAppInstallation "-r" "$@"

#
# Configure 'main.cf' for loopback-only operation:
#
[[ -e "${POSTFIX_DIR}/${POSTFIX_CONFIG_FILE}" ]] || \
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" \
                "Cannot locate the ${SET_NAME} '${POSTFIX_CONFIG_FILE}' file ! "

CONFIG_FILE_1_ORIGINAL="append_dot_mydomain = no"
CONFIG_FILE_1_REPLACE="append_dot_mydomain = yes"

CONFIG_FILE_2_ORIGINAL="mydestination = "
CONFIG_FILE_2_REPLACE="\$myhostname, localhost.\$mydomain, \$mydomain"

CONFIG_FILE_3_ORIGINAL="inet_interfaces = all"
CONFIG_FILE_3_REPLACE="inet_interfaces = loopback-only"

QualifySudo
sudo sed -r -i -e "s|${CONFIG_FILE_1_ORIGINAL}|${CONFIG_FILE_1_REPLACE}|" \
        "${POSTFIX_DIR}/${POSTFIX_CONFIG_FILE}"

sudo sed -r -i -e "s|(${CONFIG_FILE_2_ORIGINAL})(.*$)|\1${CONFIG_FILE_2_REPLACE}|" \
        "${POSTFIX_DIR}/${POSTFIX_CONFIG_FILE}"

sudo sed -r -i -e "s|${CONFIG_FILE_3_ORIGINAL}|${CONFIG_FILE_3_REPLACE}|" \
        "${POSTFIX_DIR}/${POSTFIX_CONFIG_FILE}"

#
# Configure '/etc/aliases' to foward mail for 'root' to the target email addr:
#
MAIL_ALIAS="root"
NEW_MAIL_ALIAS="${MAIL_ALIAS}:          ${TARGET_EMAIL_ADDRESS}"

sudo sed -r -i -e "/^${MAIL_ALIAS}:/d" \
        "${MAIL_ALIASES_DIR}/${MAIL_ALIASES_FILE}"

echo "${NEW_MAIL_ALIAS}" | \
        sudo tee -a 1>/dev/null "${MAIL_ALIASES_DIR}/${MAIL_ALIASES_FILE}"

#
# Pick up the new mail alias, then restart postfix to pick up the new config:
#
sudo newaliases

sudo service postfix restart

InstallComplete
