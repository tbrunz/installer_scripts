#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Script to manage Bloodhound project setup
# ----------------------------------------------------------------------------
#

#
# Host defines
#
BHOUND_PORT=80
TRACD_PORT=8000
WEB_HOST=$( uname -n )
WEB_DOMAIN=example.com
WEBMASTER=webmaster

#
# Account defines
#
USER_UBERSVN=$( grep -i ubersvn /etc/passwd | cut -d ':' -f 1 )
USER_APACHE=$( grep /var/www /etc/passwd | cut -d ':' -f 1 )
USER_POSTGRES=$( grep -i postgres /etc/passwd | cut -d ':' -f 1 )
USER_BHOUND=$( grep -i bloodhound /etc/passwd | cut -d ':' -f 1 )

#
# Application defines
#
BLOODHOUND_PROJ_BASE=/var/lib/bloodhound
BLOODHOUND_APP_BASE=/opt/bloodhound
BLOODHOUND_ENV_SETUP_PY=bloodhound_setup.py

SUBVERSION_APP_BASE=/opt/ubersvn
SUBVERSION_REPO_BASE=/var/lib/subversion

#
# Apache Web Server defines
#
APACHE_APP_BASE=/etc/apache2
APACHE_APP_BASE_RHEL=/etc/httpd
APACHE_LOG_DIR=/var/log/apache2

APACHE_CONF_FILE_RHEL=conf/httpd.conf
APACHE_CONF_FILE_DEBIAN=apache2.conf
APACHE_SERVICE=apache2

APACHE_SITES_AVAIL=sites-available
APACHE_SITES_ENABLED=sites-enabled
APACHE_VHOST_ENABLE_CMD="a2ensite"
APACHE_VHOST_DISABLE_CMD="a2dissite"

APACHE_BH_ERROR_LOG=bloodhound-error_log
APACHE_BH_ACCESS_LOG=bloodhound-access_log
APACHE_WSGI_DAEMON_PROC=bloodhound_tracker

LDAP_AUTH_NAME="Bloodhound Login - Work Authentication"
LDAP_SERVER_URL=ldaps://ldap.example.com
LDAP_ORG_UNIT=ou=personnel
LDAP_DOM_COMP=dc=dir,dc=example,dc=com
LDAP_COM_NAME=cn=my-server

#
# Project defines
#
PROJECT_SITE_DIR=site/cgi-bin
PROJECT_WSGI_FILE=trac.wsgi

PROJECT_CONF_FILE=conf/base.ini
PROJECT_HTDOCS_DIR=htdocs

CONF_FILE_LOGO_SECTION=header_logo
CONF_FILE_LOGO_KEY=src

CONF_FILE_AUTH_SECTION=account-manager
CONF_FILE_AUTH_KEY=htdigest_file
PW_DIGEST_FILE=bloodhound.htdigest

VIRT_HOST_FILE=bloodhound
VIRT_HOST_FILE_TAG="</VirtualHost>"

#
# Database defines
#
DB_USER_BHOUND=bloodhound
DB_DATABASE_BHOUND=bloodhound

DB_TYPE=postgres

DB_USER_STR="-S -P -R -E -D ${DB_USER_BHOUND}"
DB_CREATE_STR="-O ${DB_USER_BHOUND} -E UTF-8 ${DB_DATABASE_BHOUND}"

DB_CREATE_USER_STR="createuser -U ${USER_POSTGRES} ${DB_USER_STR}"
DB_CREATE_BH_DB_STR="createdb -U ${USER_POSTGRES} ${DB_CREATE_STR}"

DB_CREATE_STR="createdb -U ${USER_POSTGRES} -O ${DB_USER_BHOUND} -E UTF-8"
DB_DROP_STR="dropdb -U ${USER_POSTGRES}"


############################################################################
############################################################################
#
# ERROR HANDLING
#
############################################################################
############################################################################

############################################################################
#
# Script Error Exit Codes:
#
ERR_PARSING=1
ERR_BAD_APP_ENV=2
ERR_BAD_PROJ_ENV=4
ERR_FILESYS=8
ERR_CMD_FAIL=16
ERR_USER_ABORT=32

############################################################################
#
# Display App Error: Missing/defective project environment.
#
DisplayErrBadAppEnv() {
    echo "Error with the host/application environment: "
    echo "${1} ! "
    
    if [ -n "${2}" ]; then
        echo "${2} "
    fi
    
    exit ${ERR_BAD_APP_ENV}
}

############################################################################
#
# Display App Error: Missing/defective project environment.
#
DisplayErrBadProjectEnv() {
    echo "Error with the Bloodhound environment for project '${PROJECT}': "
    echo "${1}. "
    
    if [ -n "${2}" ]; then
        echo "${2} "
    fi
    
    exit ${ERR_BAD_PROJ_ENV}
}

############################################################################
#
# Display file system error; the parameter is the specific error
#
DisplayCommandFailureErr() {
    echo "Command error: ${1} "
    
    exit ${ERR_CMD_FAIL}
}

############################################################################
#
# Display file system error; the parameter is the specific error
#
DisplayFileSystemErr() {
    echo "File sytem error: ${1} "
    
    exit ${ERR_FILESYS}
}

############################################################################
#
# Display parsing error: Given switch must be the only cmd line argument.
#
DisplayErrParsing_OnlyArg() {
    echo -n "${THIS_SCRIPT}: Parsing error: "
    echo    "Cannot include '-${SWITCH}' with other arguments. "
    
    exit ${ERR_PARSING}
}

############################################################################
#
# Display parsing error: A switch is followed by a parameter starting 
# with a hyphen... It's either a missing parameter or an invalid one.
#
DisplayErrParsing_ArgWithLeadHyphen() {
    echo -n "${THIS_SCRIPT}: Parsing error: "
    echo    "'-${SWITCH}' argument, '${VALUE}', cannot start with '-'. "
    
    exit ${ERR_PARSING}
}

############################################################################
#
# Display parsing error: A (second) instance was found of a non-switch 
# token (value) which is not preceded by a switch; can only have one.
#
DisplayErrParsing_ArgHasNoSwitch() {
    echo -n "${THIS_SCRIPT}: Parsing error: "
    echo    "No switch for unmatched argument '${VALUE}'. "
    
    exit ${ERR_PARSING}
}

############################################################################
#
# Display parsing error: Unknown switch on command line.
#
DisplayErrParsing_UnknownSwitch() {
    echo -n "${THIS_SCRIPT}: Parsing error: "
    echo    "Unrecognized switch, '-${SWITCH}'. "
    
    exit ${ERR_PARSING}
}

############################################################################
#
# Display parsing error: An extraneous switch is specified.
#
DisplayErrParsing_ExtraneousSwitch() {
    echo -n "${THIS_SCRIPT}: Parsing error: "
    echo    "Extraneous switch, '-${SWITCH} ${VALUE}'. "
    
    exit ${ERR_PARSING}
}

############################################################################
#
# Display parsing error: A switch is specified without a parameter.
#
DisplayErrParsing_DanglingSwitch() {
    echo -n "${THIS_SCRIPT}: Parsing error: "
    echo    "Switch '-${SWITCH}' has no parameter value. "
    
    exit ${ERR_PARSING}
}

############################################################################
############################################################################
#
# COMMON UTILITY ROUTINES
#
############################################################################
############################################################################

############################################################################
#
# Save/Restore the user's PWD environment variables.
#
Save_PWD_State() {
    SAVED_PWD=$( pwd )
    SAVED_OLDPWD=$( env | grep OLDPWD= | cut -d '=' -f 2 )
}

Restore_PWD_State() {
    cd ${SAVED_OLDPWD}
    cd ${SAVED_PWD}
}
    
############################################################################
#
# Move a file (i.e., rename) while making a backup of the target.
#
Move_File_with_Backup() {

    # Move the ${2} file (if it exists) to a backup (deleting the backup), 
    # then move the ${1} file to the name provided by ${2}.
    # 
    if [ -e "${2}.bak" ]; then rm -f "${2}.bak"; fi
    
    mv "${2}" "${2}.bak"
            
    mv "${1}" "${2}"
}

############################################################################
#
# Get the name of this script (for 'usage' prompts).
#
Get_Script_Name() {
    SCRIPT="${BASH_SOURCE[0]}"
    
    # If the name of the script is a symlink, de-reference it:
    #
    while [ -h "${SCRIPT}" ] ; do SCRIPT="$(readlink "${SCRIPT}")" ; done
    
    # Extract just the name of the script from the path (sans '.sh')
    # and get the name of the directory the script is in:
    #
    THIS_SCRIPT=$( basename ${SCRIPT} .sh )
    SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
}

############################################################################
#
# Get the lowercase first letter of a string.
#
Get_First_Char_Lowercase() {

    echo $( printf %s "${1}" | cut -c 1 | tr [:upper:] [:lower:] )
}

############################################################################
#
# Display a prompt asking a Yes/No question, repeat until a valid input.
# Allow for a blank input to be defaulted.  Automatically appends "(y/n)"
# to the prompt, capitalized according to the value of DEF_INPUT.
#
# INPUTS:  ${1}=DEF_INPUT, ${2}=PROMPT
# OUTPUTS: ${UINPUT} (1 char, lowercase)
#
# usage: RESULT=$( Get_Yes_No_Defaulted "<def>" "<prompt>" )
#
Get_Yes_No_Defaulted() {
    
    if [ $( Get_First_Char_Lowercase "${1}" ) = 'y' ]; then
        YES_NO="Y/n"
    else
        YES_NO="y/N"
    fi 
    PROMPT=${2}" ("${YES_NO}")"
    
    unset UINPUT
    until [ "${UINPUT}" = "y" -o "${UINPUT}" = "n" ]; do
    
        read -p "${PROMPT} " UINPUT
    
        if [ -z "${UINPUT}" ]; then UINPUT="${1}"; fi
    
        UINPUT=$( Get_First_Char_Lowercase "${UINPUT}" )
    done
}

############################################################################
#
# Get a Key-Value pair from a config file.
#
# $1 = Path to config file    $2 = Section string    $3 = Key string
# Returns the key's value in the script variable ${KEY_VALUE}.
#
Get_Config_File_Value() {

    # Parse the config file by treating the file as a set of 
    # "multi-line records", where each record is composed of a 
    # '[section]' plus a set of 'key=value' fields.
    #
    # If we can't parse the file, return "?";
    # If we can't find the section, return "?";
    # If we can't find the key-value pair, return "*";
    # if we find the key, but the value is 'missing', return "";
    # Otherwise, return the value associated with the key.  
    # 
    KEY_VALUE=$( awk ' 
    
        BEGIN { FS="\n"; RS="["                     # Separate by sections
            Key_Value = "?"                         # Default response
        }
        
        $1 ~ Config_Section {                       # Is this OUR section?
            Key_Match = "[[:space:]]*" Section_Key "[[:space:]]*="
            
            for (Field=2; Field<=NF; Field++) {     # Step through fields
            
                if ($Field ~ Key_Match) {           # is this OUR key?
                    if (split($Field, Token_ary, "=[[:space:]]*") > 1)
                        Key_Value = Token_ary[2]
                        
                    else Key_Value = ""
                    exit                            # If was our key, done!
                }
            }
            Key_Value = "*"                         # No key in our section
            exit
        } 
        
        END { printf("%s\n", Key_Value) }           # Return the key value
        
        ' Config_Section="${2}" Section_Key="${3}" "${1}" )
}

############################################################################
#
# Set a Key-Value pair in a config file.
#
# $1 = Path to config file    $2 = Section string
# $3 = Key string             $4 = Value string
#
Set_Config_File_Value() {

    # We want the owner and permissions of the replacement file 
    # to match the existing files.  The easiest way to do this is to 
    # copy the existing file with the new name, then overwrite it.
    #
    cp -pf "${1}" "${1}___TeMp_fIlE____"
    
    # Test the assumption that we can write to this directory...
    #
    if [ ! -e "${1}___TeMp_fIlE____" ]; then
        
        echo "Cannot rewrite the '${1}' file for '${PROJECT}' ! "
        exit ${ERR_FILESYS}
    fi
    
    # Read the 'conf' file once again, this time actually copying it to 
    # 'stdout'; we copy it by "multi-line records", where each record 
    # is a [section] + 'key=value' lines. When we reach our logo spec, 
    # we replace it with a new line we generate on the spot...
    # 
    # We *could* test the 'awk' call to ensure it completes w/o error...
    #
    awk ' 
        BEGIN { FS="\n"; RS="["; OFS="\n"           # Separate by sections
        }
        
        $1 ~ Config_Section {                       # Is this OUR section?
            Key_Match = "[[:space:]]*" Section_Key "[[:space:]]*="
            
            printf("[%s\n", $1)                     # Print section header
            
            for (Field=2; Field<=NF; Field++) {     # Step through fields
                if ($Field !~ Key_Match)            # Print if not ours
                
                    if ($Field !~ "^[[:space:]]*$") # Is field blank?
                        print $Field
            }
            
            printf("%s = %s\n", Section_Key, Key_Value)     # Write our K-V
            printf("\n")                            # Blank btw sections
            next                                    # Skip to next record
        } 
        
        {   if ($1 ~ "]")                           # Section record? 
                printf("[")                         # Splitting drops this
        
            for (Field=1; Field<NF; Field++)        # Step through fields
                print $Field                        # Output verbatim
                
            if ($NF !~ "^[[:space:]]*$")            # Is last field blank?
                print $NF                           # No - print it, too
        }
        
        ' Config_Section="${2}" Section_Key="${3}" Key_Value="${4}"       \
                "${1}" > "${1}___TeMp_fIlE____"
            
    Move_File_with_Backup "${1}___TeMp_fIlE____" "${1}"
}

############################################################################
#
# Verify that the user can obtain privileges; bail if not.
#
Check_Sudo_Privileges() {
    #
    # Simple, silent test to see if 'sudo' has already been obtained.
    # Serves two purposes, as it also gains 'sudo', if eligible.
    #
    ls /root > /dev/null 2>&1
    
    if [ $? != 0 ]; then
        echo -n "${THIS_SCRIPT}: Cannot run this script "
        echo    "without 'sudo' privileges. "
        
        exit ${ERR_CMD_FAIL}
    fi
}

############################################################################
#
# Verify that the user has launched us using 'sudo':
#
Check_Run_As_Root() {

    ls /root > /dev/null 2>&1

    if [ ${?} -ne 0 ]; then

        echo -n  "This script must be run as 'root'; "
	    echo     "try \"sudo ${THIS_SCRIPT}\". "

        exit ${ERR_CMD_FAIL}
    fi
}

############################################################################
#
# Display the script version.
#
Display_Script_Version() {
    echo "${THIS_SCRIPT}, version ${VERSION} "
    exit
}

############################################################################
#
# Display the one-line 'usage' prompt.
#
usage() {
    echo -n "usage: ${THIS_SCRIPT} [-a] <project name> ; "
    echo    "use -h for help... "
}

############################################################################
#
# Display the help information (-h).
#
Display_Help_Summary() {
    echo
    echo "${THIS_SCRIPT} -u                  = Create Bloodhound DB user "
    echo "${THIS_SCRIPT} -c  <project name>  = Create a project database "
    echo "${THIS_SCRIPT} -d  <project name>  = Drop a project database "
    echo "${THIS_SCRIPT} -e  <project name>  = Create project environment "
    echo "${THIS_SCRIPT} -P  <project name>  = Add/remove common PW file "
    echo "${THIS_SCRIPT} -t  <project name>  = Test-drive project enviro "
    echo "${THIS_SCRIPT} -s  <project name>  = Create project website "
    echo "${THIS_SCRIPT} -L  <project name>  = Add/remove project logo "
    echo "${THIS_SCRIPT} -r  <project name>  = Remove project env+website "
    echo "${THIS_SCRIPT} -V [<project name>] = Validate [project] config "
    echo "${THIS_SCRIPT} -l                  = List all project enviros "
    echo "${THIS_SCRIPT} -H                  = Display the man page "
    echo "${THIS_SCRIPT} [-a] <project name> = Create all project elements "
    echo
    exit
}

############################################################################
#
# Display the man page (-H).
#
Display_Man_Page() {
    echo 
    echo "NAME "
    echo "  ${THIS_SCRIPT} - Manage Bloodhound multi-project configuration "
    echo
    echo "SYNOPSIS "
    echo "  ${THIS_SCRIPT} -u | -h "
    echo "  ${THIS_SCRIPT} -c | -d  <project name> "
    echo "  ${THIS_SCRIPT} -e | -P | -t | -s | -L  <project name> "
    echo "  ${THIS_SCRIPT} [ -a ] <project name> "
    echo "  ${THIS_SCRIPT} -l | -V  [ <project name> ] "
    echo
    echo "DESCRIPTION "
    echo "  This script does the following: "
    echo "  * Creates a PostgreSQL user for Bloodhound. "
    echo "  * Creates a new PGSQL database for a Bloodhound project. "
    echo "  * Drops a Bloodhound project database from PGSQL. "
    echo "  * Creates a new project environment for Bloodhound. "
    echo "  * Configures a B/H project env to use a common PW digest. "
    echo "  * Tests a new Bloodhound project environment. "
    echo "  * Deploys a Bloodhound project web site for Apache. "
    echo
    echo -n "  Mandatory arguments to long options are mandatory "
    echo    "for short options, too. "
    echo
    echo "    -u --user "
    echo "          Create an initial PostgreSQL Bloodhound user "
    echo
    echo "    -a --all[=PROJECT] "
    echo "          Create all elements for a new Bloodhound project "
    echo
    echo "    -c --createdb=PROJECT "
    echo "          Create a new Bloodhound project database "
    echo
    echo "    -d --dropdb=PROJECT "
    echo "          Drop an existing Bloodhound project database "
    echo
    echo "    -e --environment=PROJECT "
    echo "          Create a new Bloodhound project environment "
    echo
    echo "    -P --pw-method=PROJECT "
    echo "          Choose the authentication method for a project "
    echo
    echo "    -t --test=PROJECT "
    echo "          Test a Bloodhound project with the internal web server "
    echo
    echo "    -s --site-deploy=PROJECT "
    echo "          Deploy a Bloodhound project site for use with Apache "
    echo
    echo "    -L --logo=PROJECT "
    echo "          Add or remove a Logo file in a project environment "
    echo
    echo "    -l --list "
    echo "          List all Bloodhound project environments "
    echo
    echo "    -V --validate[=PROJECT] "
    echo "          Validate the environment (and, optionally, project) "
    echo
    echo "    -h --help "
    echo "          Display the help synopsis "
    echo
    echo "The PostgreSQL user only needs to be created once. "
    echo
    echo "The project name must be all lower-case, and may contain only "
    echo "letters, numbers, '-' and '_'. "
    echo
    echo "The common password digest file need not already exist; this "
    echo "script will create it, if missing, using the digest for the "
    echo "specified project."
    echo
    echo "The 'bloodhound' virtual host file must already exist in the "
    echo "Apache directory.  This script will provide the text that needs "
    echo "to be added to it for the project environment it creates. "
    echo
    echo "Typical usage (steps covered by the '--all' switch): "
    echo "  1. Create a PostgreSQL database for the project "
    echo "  2. Create a Bloodhound environment for the project "
    echo "  3. Change the project's password digest to the common file "
    echo "  4. Test the project with the internal web server "
    echo "  5. Deploy the project's Apache web site "
    echo "  6. Test the deployed site served by the Apache Web Server "
    echo
    
    exit
}


############################################################################
############################################################################
#
# COMMAND LINE PARSING
#
############################################################################
############################################################################

############################################################################
#
# Should we display the help info?
# Note: '-h' must be the only command-line argument.
#
Check_Switch_Help() {
    if [[ "${SWITCH}" == "h" || "${CUT_SWITCH}" == "hel" ]]; then
        if [ ${1} -eq 1 ]; then
            Display_Help_Summary
        else
            DisplayErrParsing_OnlyArg
        fi
    fi
}

############################################################################
#
# Should we display the man page?
# Note: '-H' must be the only command-line argument.
#
Check_Switch_Man_Page() {
    if [[ "${SWITCH}" == "H" || "${CUT_SWITCH}" == "man" ]]; then
        if [ ${1} -eq 1 ]; then
            Display_Man_Page
        else
            DisplayErrParsing_OnlyArg
        fi
    fi
}

############################################################################
#
# Should we display the script version?
# Note: '-v' must be the only command-line argument.
#
Check_Switch_Version() {
    if [[ "${SWITCH}" == "v" || "${CUT_SWITCH}" == "ver" ]]; then
        if [ ${1} -eq 1 ]; then
            Display_Script_Version
        else
            DisplayErrParsing_OnlyArg
        fi
    fi
}

############################################################################
#
# Should we display the script version?
# Note: '-u' must be the only command-line argument.
#
Check_Switch_User() {
    if [[ "${SWITCH}" == "u" || "${CUT_SWITCH}" == "use" ]]; then
        
        Check_Run_As_Root
        
        if [ ${1} -eq 1 ]; then
            Create_Pgsql_User
        else
            DisplayErrParsing_OnlyArg
        fi
    fi
}

############################################################################
#
# Should we list the environments?
# Note: '-l' must be the only command-line argument.
#
Check_Switch_List() {
    if [[ "${SWITCH}" == "l" || "${CUT_SWITCH}" == "lis" ]]; then
        
        Check_Run_As_Root
        
        if [ ${1} -eq 1 ]; then
            List_Project_Environments
        else
            DisplayErrParsing_OnlyArg
        fi
    fi
}

############################################################################
#
# Should we validate the environment?
# Note: '-V' must be the only command-line argument, 
# but may have a project name as an argument (optional).
#
Check_Switch_Validate() {
    if [[ "${SWITCH}" == "V" || "${CUT_SWITCH}" == "val" ]]; then
        
        Check_Run_As_Root
        
        if [ ${1} -le 2 ]; then
            Validate_Host_Apps_Project ${2}
        else
            DisplayErrParsing_OnlyArg
        fi
    fi
}

############################################################################
#
# Check for & handle exclusive command line switches.  These are switches 
# that are exclusive of any other switches appearing on the command line.
# 
# We do this by running a (variable) list of individual switch checks.
# If any one of them fails (i.e., not the only switch), the script bails; 
# otherwise the action is performed, which also terminates the script.
#
# If none of this switches matches, nothing is done and we simply return. 
#
Check_For_Exclusive_Switches() {
    
    Check_Switch_Help ${1}
    Check_Switch_Man_Page ${1}
    Check_Switch_Version ${1}
    Check_Switch_User ${1}
    Check_Switch_List ${1}
    Check_Switch_Validate ${1} ${2}
}

############################################################################
#
# Parse the command line argument list
#
Parse_Command_Line_Args() {    
    unset SWITCH
    unset VALUE
    
    unset COMMAND
    unset PROJECT
    
    NUM_OF_PARAMS=0

    for TOKEN in $@ ; do
        
        # Are we expecting to parse a value argument to a switch?
        #
        if [ -n "${SWITCH}" ] ; then  
            
            # Save the token as the switch's value, but make sure it 
            # doesn't start with a hyphen, which would be ambiguous.
            #
            VALUE=${TOKEN}
            
            if [ $( printf %s "${VALUE}" | cut -c 1 ) = "-" ]; then 
                DisplayErrParsing_ArgWithLeadHyphen
            fi
            
        # Otherwise we expect to find a switch:
        # 
        elif [ $( printf %s "${TOKEN}" | cut -c 1 ) = "-" ]; then
            
            # Switch: Allow both '-sargument' or '-s argument' forms,
            # and the '--long-name=argument' form.
            #
            SWITCH=$( printf %s "${TOKEN}" | cut -c 2 )
            VALUE=$(  printf %s "${TOKEN}" | cut -c 3- )
            
            # We could have "-" or "--" or "-a" or "-aArg" (short form) 
            # or "--alpha" or "--alpha=" or "--alpha=beta" (long form)
            #
            if [ -z "${SWITCH}" ]; then 
                
                # "-" typically means "take the input from 'stdin'".
                #
                DisplayErrParsing_UnknownSwitch
                
            elif [ "${SWITCH}" = "-" -a -z "${VALUE}" ]; then
                
                # "--" typically means "end of switches; parameters follow".
                #
                DisplayErrParsing_UnknownSwitch
            
            elif [ "${SWITCH}" = "-" -a -n "${VALUE}" ]; then 
                
                # This is the "--long-form" -- which one?
                #
                SWITCH=$( printf %s "${VALUE}" | cut -d '=' -f 1 )
                
                # If there's no '=', then SWITCH got it all; in that
                # case, erase VALUE; otherwise, cut after the '='.
                #
                if [ "${SWITCH}" = "${VALUE}" ]; then VALUE=""
                else
                    VALUE=$(  printf %s "${VALUE}" | cut -d '=' -f 2 )
                fi
                
                # Convert the switch to all lower case, and shorten it.
                #
                SWITCH=$( printf %s "${SWITCH}" | tr [:upper:] [:lower:] )
                CUT_SWITCH=$( printf %s "${SWITCH}" | cut -c -3 )
                
                if [ -z ${VALUE} ]; then
                    #
                    # We can't have a form "--alpha beta"...
                    # But we can have a form "--exclusive"
                    #
                    Check_For_Exclusive_Switches ${#} ${2}
                fi
                
                # Translate long-form switches to short form.
                #
                case "${CUT_SWITCH}" in
                
                "all")
                    SWITCH="a"
                    ;;
                "cre")
                    SWITCH="c"
                    ;;
                "dro")
                    SWITCH="d"
                    ;;
                "env")
                    SWITCH="e"
                    ;;
                "pw-")
                    SWITCH="P"
                    ;;
                "tes")
                    SWITCH="t"
                    ;;
                "sit")
                    SWITCH="s"
                    ;;
                "log")
                    SWITCH="L"
                    ;;
                "rem")
                    SWITCH="r"
                    ;;
                *)
                    SWITCH="-"${SWITCH}
                    DisplayErrParsing_UnknownSwitch
                esac
                
            # Else SWITCH & VALUE are correctly set 
            # (and VALUE may be "", if the form is "-a Arg").
            fi
        else
            # We have a "naked token", which must be a project name:
            #
            VALUE=${TOKEN}
        fi
        
        # At this point, we have either:
        #     1) Switch + Value
        #     2) Switch (only)
        #     3) Value, but no Switch
        #
        if [ -z "${SWITCH}" ]; then
            
            # 3) Value, but no Switch:
            # If this is the first non-switch argument we find when we were 
            # expecting a switch, then we can safely interpret it as the 
            # name of the project to create; the implied switch is '-a':
            #
            if [ -z "${COMMAND}" ]; then 
                SWITCH="a"
                
            # But if it happens a second time, it's a parsing error...
            #
            else
                DisplayErrParsing_ArgHasNoSwitch
            fi
        fi
            
        # Make sure the switch isn't one that requires exclusivity:
        #
        Check_For_Exclusive_Switches ${#} ${2}
    
        # Now we do have a switch, but do we need to loop for a value?
        # If yes, then we're done with this loop; we get the value in 
        # the next iteration.  Otherwise, we have Switch+Value: Process it.
        #
        if [ -n "${VALUE}" ]; then
            
            # Assume a screw-up awaits us...
            ERROR=true
            
            case "${SWITCH}" in
                
            a)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="CREATE_ALL"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            c)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="CREATE_DB"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            d)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="DROP_DB"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            e)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="CREATE_ENV"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            P)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="AUTH_METHOD"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            t)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="TEST_NEW_ENV"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            s)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="DEPLOY_SITE"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            L)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="INSERT_LOGO"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            r)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="REMOVE_ENV"
                    PROJECT=${VALUE}
                    unset ERROR
                fi
                ;;
            *)  
                DisplayErrParsing_UnknownSwitch
            esac
        
            # If ${ERROR} is set, then we have an extraneous switch error.
            #
            if [ -n "${ERROR}" ]; then
                DisplayErrParsing_ExtraneousSwitch
            fi
            
            # We've parsed a switch-value pair; reset the variables.
            #
            NUM_OF_PARAMS=$( expr ${NUM_OF_PARAMS} + 1 )
            
            unset SWITCH
            unset VALUE
        fi
    done
    
    # Last check: Do we have a dangling switch as the final argument?
    #
    if [ -n "${SWITCH}" ]; then
    
        if [ $( printf %s "acdeptsr" | grep "${SWITCH}" ) ]; then
            DisplayErrParsing_DanglingSwitch
        else
            DisplayErrParsing_UnknownSwitch
        fi
    fi
}


############################################################################
############################################################################
#
#  VALIDATE ENVIRONMENT & ARGUMENTS
#
############################################################################
############################################################################

############################################################################
#
# Validate the host on this machine: Everything installed?
#
Validate_Host_Accounts() {

    if [ -z "${WEB_HOST}" ]; then
        DisplayErrBadAppEnv "Cannot determine the 'localhost' name"
    fi
    
    if [ -z "${USER_APACHE}" ]; then
        DisplayErrBadAppEnv "Cannot find an Apache system account"
    fi
    
    if [ -z "${USER_POSTGRES}" ]; then
        DisplayErrBadAppEnv "Cannot find a PostgreSQL system account"
    fi
    
    if [ -z "${USER_BHOUND}" ]; then
        DisplayErrBadAppEnv "Cannot find a Bloodhound system account"
    fi
    
    GROUP_BHOUND=$( grep $(                                               \
                grep ${USER_BHOUND} /etc/passwd | cut -d ':' -f 4         \
                        ) /etc/group | cut -d ':' -f 1 )
    
    if [ -z "${GROUP_BHOUND}" ]; then
        DisplayErrBadAppEnv "Cannot find a Bloodhound system group"
    fi
    
    if [ -z "${USER_UBERSVN}" ]; then
        DisplayErrBadAppEnv "Cannot find an UberSVN system account"
    fi
}

############################################################################
#
# Validate the applications on this machine: Everything installed?
#
Validate_Host_Applications() {
    
    # Start with the Apache Web Server:
    #
    if [ -e ${APACHE_APP_BASE}/${APACHE_CONF_FILE_RHEL} ]; then
        PLATFORM=RHEL
        
    elif [ -e ${APACHE_APP_BASE}/${APACHE_CONF_FILE_DEBIAN} ]; then
        PLATFORM=DEBIAN
        
    elif [ -e ${APACHE_APP_BASE_RHEL}/${APACHE_CONF_FILE_RHEL} ]; then
    
        DisplayErrBadAppEnv "Script not compatible with RHEL 'httpd' app" \
            "You need to run the 'apache2-fixup' script first."
    else
        DisplayErrBadAppEnv "Cannot find the Apache application files"    \
            "Expected them in '${APACHE_APP_BASE}'..."
    fi
        
    if [ ! -d ${APACHE_LOG_DIR} ]; then
        DisplayErrBadAppEnv "Cannot find the Apache logs directory"       \
            "Expected it at '${APACHE_LOG_DIR}'..."
    fi
    
    # Now check Bloodhound:
    #
    if [ ! -d ${BLOODHOUND_APP_BASE} ]; then
        DisplayErrBadAppEnv "Cannot find the Bloodhound application"      \
            "Expected it in '${BLOODHOUND_APP_BASE}'..."
    fi
    
    # Find/set the version of Python being used by Bloodhound:
    #
    BLOODHOUND_PYTHON=$( basename $(                                      \
            ls -d ${BLOODHOUND_APP_BASE}/lib/*ython* 2>/dev/null          \
                                    ) 2>/dev/null )
    
    if [ -z ${BLOODHOUND_PYTHON} ]; then
        DisplayErrBadAppEnv "Cannot find the Bloodhound python directory" \
            "Expected it in '${BLOODHOUND_APP_BASE}/lib/'..."
    fi
    
    # Find/set the Bloodhound installer directory: 
    # (Part of the install tarball that contains the 'setup.py' script.)
    #
    INSTALLER_DIR=$( find ${BLOODHOUND_APP_BASE} -type d -name installer )
    
    if [ ! -e ${INSTALLER_DIR}/${BLOODHOUND_ENV_SETUP_PY} ]; then
        DisplayErrBadAppEnv                                               \
            "Cannot locate the '${BLOODHOUND_ENV_SETUP_PY}' file"         \
            "Expected to find it in '${INSTALLER_DIR}'."
    fi
}

############################################################################
#
# Validate the application databases on this machine: Everything there?
#
Validate_Host_Databases() {
    
    if [ ! -d ${BLOODHOUND_PROJ_BASE} ]; then
        DisplayErrBadAppEnv "Cannot find the Bloodhound environments"     \
            "Expected them in '${BLOODHOUND_PROJ_BASE}'..."
    fi
    
    if [ ! -d ${SUBVERSION_APP_BASE} ]; then
        DisplayErrBadAppEnv "Cannot find the Subversion application"      \
            "Expected it in '${SUBVERSION_APP_BASE}'..."
    fi
    
    if [ ! -d ${SUBVERSION_REPO_BASE} ]; then
        DisplayErrBadAppEnv "Cannot find the Subversion repository"       \
            "Expected it in '${SUBVERSION_REPO_BASE}'..."
    fi
}

############################################################################
#
# Validate the existence of the project given as a parameter, by 
# verifying that it has a Bloodhound environment directory.
#
Validate_Project_Directory() {

    RESULT=$( ls -lF ${BLOODHOUND_PROJ_BASE}/${PROJECT} 2>/dev/null )

    if [[ ${?} -ne 0 || $( printf %s ${RESULT} | cut -c 1 ) == "-" ]]; then
        DisplayErrBadProjectEnv                                           \
           "Cannot locate its Bloodhound environment directory" \
           "(Enter '${THIS_SCRIPT} -l' to list the environments.) "
    fi
}

############################################################################
#
# Validate everything for the user, including, optionally, a project.
#
Validate_Host_Apps_Project() {
    #
    # Entering "-V" and another switch is a boo-boo...
    #
    if [[ -n "${1}" && $( echo ${1} | cut -c 1 ) = "-" ]]; then
        DisplayErrParsing_OnlyArg
    fi
    
    Validate_Host_Accounts
    echo "Host accounts good... "
    
    Validate_Host_Applications
    echo "Host applications good... "
    
    if [ -n "${1}" ]; then
        PROJECT=${1}
        Validate_Project_Directory
        echo "Project directory good..."
    fi
    exit
}


############################################################################
############################################################################
#
#  SUPPORT FILES
#
############################################################################
############################################################################

############################################################################
#
# Create a new Apache Virtual Host file for the Bloodhound web site(s).
#
Virtual_Host_File_Create_New_File() {

    # Is there already a Bloodhound Virtual Host file?
    #
    if [ -e ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE} ];
    then
        echo "The '${VIRT_HOST_FILE}' virtual host file already exists... "
        Get_Yes_No_Defaulted "No" "Do you want to erase & replace it?"
        
        if [ "${UINPUT}" = "n" ]; then
            exit
        fi
    fi

    # Copy the virtual host file below into a temp file:
    #
    PARAMETER_VHOST_FILE=$( mktemp )

    cat > ${PARAMETER_VHOST_FILE} << 'EOF'
#
# Bloodhound Project VirtualHost File
#
LDAPTrustedGlobalCert CA_BASE64 /etc/pki/tls/certs/ca-bundle.crt
#LDAPVerifyServerCert off
#NSSEnforceValidCerts off

<VirtualHost *:%BHOUND_PORT%>
    ServerAdmin %WEBMASTER%@%WEB_HOST%.%WEB_DOMAIN%
    DocumentRoot %BLOODHOUND_PROJ_BASE%
    ServerName %WEB_HOST%.%WEB_DOMAIN%
    ErrorLog %APACHE_LOG_DIR%/%APACHE_BH_ERROR_LOG%
    CustomLog %APACHE_LOG_DIR%/%APACHE_BH_ACCESS_LOG% common

    WSGIDaemonProcess %APACHE_WSGI_DAEMON_PROC% user=%USER_BHOUND% group=%GROUP_BHOUND% python-path=%BLOODHOUND_APP_BASE%/lib/%BLOODHOUND_PYTHON%/site-packages

    <LocationMatch "[^/]+/login">
        AuthType Basic
        AuthName "%LDAP_AUTH_NAME%"
        AuthBasicProvider ldap
        AuthzLDAPAuthoritative off
	    AuthLDAPGroupAttribute uniquemember
	    AuthLDAPURL %LDAP_SERVER_URL%/%LDAP_ORG_UNIT%,%LDAP_DOM_COMP%?uid
        Require ldap-group %LDAP_COM_NAME%,%LDAP_ORG_UNIT%,%LDAP_DOM_COMP%
    </LocationMatch>
</VirtualHost>
EOF
 
    # Edit the file to replace the %PARAMETER% values:
    #
    SUBBED_VHOST_FILE=$( mktemp )
    
    cat ${PARAMETER_VHOST_FILE}                                         | \
    sed -e "s!%WEBMASTER%!${WEBMASTER}!"                                | \
    sed -e "s!%WEB_HOST%!${WEB_HOST}!"                                  | \
    sed -e "s!%WEB_DOMAIN%!${WEB_DOMAIN}!"                              | \
    sed -e "s!%BHOUND_PORT%!${BHOUND_PORT}!"                            | \
    sed -e "s!%APACHE_LOG_DIR%!${APACHE_LOG_DIR}!"                      | \
    sed -e "s!%APACHE_BH_ERROR_LOG%!${APACHE_BH_ERROR_LOG}!"            | \
    sed -e "s!%APACHE_BH_ACCESS_LOG%!${APACHE_BH_ACCESS_LOG}!"          | \
    sed -e "s!%APACHE_WSGI_DAEMON_PROC%!${APACHE_WSGI_DAEMON_PROC}!"    | \
    sed -e "s!%USER_BHOUND%!${USER_BHOUND}!"                            | \
    sed -e "s!%GROUP_BHOUND%!${GROUP_BHOUND}!"                          | \
    sed -e "s!%BLOODHOUND_APP_BASE%!${BLOODHOUND_APP_BASE}!"            | \
    sed -e "s!%BLOODHOUND_PROJ_BASE%!${BLOODHOUND_PROJ_BASE}!"          | \
    sed -e "s!%BLOODHOUND_PYTHON%!${BLOODHOUND_PYTHON}!"                | \
    sed -e "s!%LDAP_AUTH_NAME%!${LDAP_AUTH_NAME}!"                      | \
    sed -e "s!%LDAP_SERVER_URL%!${LDAP_SERVER_URL}!"                    | \
    sed -e "s!%LDAP_ORG_UNIT%!${LDAP_ORG_UNIT}!"                        | \
    sed -e "s!%LDAP_DOM_COMP%!${LDAP_DOM_COMP}!"                        | \
    sed -e "s!%LDAP_COM_NAME%!${LDAP_COM_NAME}!"                          \
        > ${SUBBED_VHOST_FILE}
    
    # Transfer the result to the Bloodhound Virtual Host file:
    #
    cp -f ${SUBBED_VHOST_FILE}                                       \
            ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE}
    
    # Release the temp files used:
    #
    rm -f ${PARAMETER_VHOST_FILE}
    rm -f ${SUBBED_VHOST_FILE}
}

############################################################################
#
# Remove a project's <Directory> stanza from the Apache Virtual Host file.
# If a parameter is provided, then user error messages are suppressed.
# There are no side-effects in this routine if there is no project stanza.
#
Virtual_Host_File_Remove_Project_Stanza() {
    
    # If the Virtual Host file isn't there, there's nothing to do...
    #
    if [ ! -e ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE} ];
    then return
    fi
    
    # We need a temp file...
    #
    NEW_VIRT_HOST_FILE=$( mktemp )
    
    # Find & remove "WSGIScriptAlias /${PROJECT} ..." as well as all lines, 
    # inclusive, between "<Directory.*${PROJECT}" and "</Directory>".
    # Then remove any extraneous blank lines ('\s'=[:space:] for 'sed').
    #
    cat ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE} | \
    sed -e "\!WSGIScriptAlias.*/${PROJECT}!,\!</Directory>!{d}"         | \
    sed -e "/^\s*$/d"                                                     \
        > ${NEW_VIRT_HOST_FILE}
    
    # Now examine the result to see if we just removed the last stanza; 
    # If we have, then the '</LocationMatch>' line is followed 
    # immediately by the '</VirtualHost>' line:
    #
    RESULT=$( cat ${NEW_VIRT_HOST_FILE}                                 | \
            sed -n -e "\!/LocationMatch!{n;p}"                          | \
            grep "/VirtualHost" )
    
    # If there are no stanzas, then call the system applet to disable 
    # the 'bloodhound' site file, as there are no web pages to serve up.
    # But only do this if the site is currently enabled...
    #
    if [ -n "${RESULT}" ]; then
        RESULT=$( ls ${APACHE_APP_BASE}/${APACHE_SITES_ENABLED} | \
                grep "${VIRT_HOST_FILE}" )
        
        if [ -n "${RESULT}" ]; then
            ${APACHE_VHOST_DISABLE_CMD} ${VIRT_HOST_FILE}
        fi
    fi
    
    # Now copy the resulting file back in place of the original:
    #
    cp -f ${NEW_VIRT_HOST_FILE}                                      \
            ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE}
    
    # Release the temp file used:
    #
    rm -f ${NEW_VIRT_HOST_FILE}
    
    # Trigger a 'reload' for the web server so that it "forgets" this site:
    #
    if [ -n "${1}" ]; then return; fi
    
    service ${APACHE_SERVICE} reload
}

############################################################################
#
# Add a new project's <Directory> stanza to the Apache Virtual Host file.
#
Virtual_Host_File_Add_Project_Stanza() {

    # This won't work if the Bloodhound Virtual Host file doesn't exist...
    #
    if [ ! -e ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE} ];
    then
        Virtual_Host_File_Create_New_File
    else
        Virtual_Host_File_Remove_Project_Stanza "no reload"
    fi

    # Copy the stanza below into a temp file:
    #
    PARAMETER_STANZA_FILE=$( mktemp )

    cat > ${PARAMETER_STANZA_FILE} << 'EOF'

    WSGIScriptAlias /%PROJECT% %BLOODHOUND_PROJ_BASE%/%PROJECT%/%PROJECT_SITE_DIR%/%PROJECT_WSGI_FILE%
    
    <Directory %BLOODHOUND_PROJ_BASE%/%PROJECT%/%PROJECT_SITE_DIR%>
        WSGIProcessGroup %APACHE_WSGI_DAEMON_PROC%
        WSGIApplicationGroup %{GLOBAL}
        Order deny,allow
        Allow from all
    </Directory>
EOF

    # Edit the file to replace the %PARAMETER% values:
    #
    SUBBED_STANZA_FILE=$( mktemp )
    
    cat ${PARAMETER_STANZA_FILE}                                        | \
    sed -e "s!%PROJECT%!${PROJECT}!g"                                   | \
    sed -e "s!%BLOODHOUND_PROJ_BASE%!${BLOODHOUND_PROJ_BASE}!"          | \
    sed -e "s!%PROJECT_SITE_DIR%!${PROJECT_SITE_DIR}!"                  | \
    sed -e "s!%PROJECT_WSGI_FILE%!${PROJECT_WSGI_FILE}!"                | \
    sed -e "s!%APACHE_WSGI_DAEMON_PROC%!${APACHE_WSGI_DAEMON_PROC}!"      \
        > ${SUBBED_STANZA_FILE}
    
    # Integrate the result into the Virtual Host file:
    # Start by copying all but the 'end' XML tag to a temp file...
    #
    NEW_VIRT_HOST_FILE=$( mktemp )

    cat ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE} | \
        sed -e "\!${VIRT_HOST_FILE_TAG}!d" > ${NEW_VIRT_HOST_FILE}
    
    # Then append the new stanza, then append the 'end' XML tag:
    #
    cat   ${SUBBED_STANZA_FILE}  >> ${NEW_VIRT_HOST_FILE}
    echo "${VIRT_HOST_FILE_TAG}" >> ${NEW_VIRT_HOST_FILE}
    
    # Then copy the resulting file back in place of the original:
    #
    cp -f ${NEW_VIRT_HOST_FILE}                                      \
            ${APACHE_APP_BASE}/${APACHE_SITES_AVAIL}/${VIRT_HOST_FILE}
    
    # Release the temp files used:
    #
    rm -f ${PARAMETER_STANZA_FILE}
    rm -f ${SUBBED_STANZA_FILE}
    rm -f ${NEW_VIRT_HOST_FILE}
    
    # Call the system applet to enable the new 'site' file, 
    # then trigger a 'reload' for the web server:
    #
    if [ ! -e ${APACHE_SITES_ENABLED}/${VIRT_HOST_FILE} ]; then
        
        ${APACHE_VHOST_ENABLE_CMD} ${VIRT_HOST_FILE}
    fi
    
    service ${APACHE_SERVICE} reload
}

############################################################################
############################################################################
#
#  COMMAND EXECUTION
#
############################################################################
############################################################################

############################################################################
#
# Display a request that the user test a Bloodhound project website.
#
Request_User_Test_Website() {    

    # Tell the user to test with the site URL; Determine whether on not 
    # it's necessary to add a non-default port number to the URL.
    #
    if [ ${BHOUND_PORT} -eq 80 ]; then
        URL_HOST=${WEB_HOST}.${WEB_DOMAIN}
    else
        URL_HOST=${WEB_HOST}.${WEB_DOMAIN}:${BHOUND_PORT}
    fi
    
    echo    "Done. "
    echo    "Now point your browser to 'http://${URL_HOST}/${PROJECT}' "
    echo -n "and verify that the '${PROJECT}' page displays correctly"
    
    if [ -z "${1}" ]; then
        echo ". "
    else
        echo ", "
        echo "and that you can log into the wiki successfully. "
    fi
}

############################################################################
#
# -l: List the Bloodhound project environments.
#
List_Project_Environments() {

    echo
    echo -n "Bloodhound project environments are kept in "
    echo    "'${BLOODHOUND_PROJ_BASE}': "
    echo

    RESULT=$( ls -lF ${BLOODHOUND_PROJ_BASE} 2>/dev/null | grep '^d' )

    if [ -n "${RESULT}" ]; then        
        ls -lF ${BLOODHOUND_PROJ_BASE} 2>/dev/null | grep '^d'
        echo
        exit
    fi
    
    echo "No projects defined. "
    exit
}

############################################################################
#
# -u: Create a 'bloodhound' user in PostgreSQL for the Bloodhound app.
# If a parameter is provided, then user error messages are suppressed.
#
Create_Pgsql_User() {

    Validate_Host_Accounts
    
    echo "(Password request is for user '${USER_POSTGRES}'.) "
    RESULT=$( su -c "psql -l" - ${USER_POSTGRES} )

    if [ ${?} -ne 0 ]; then
        DisplayCommandFailureErr "Could not execute 'psql' command ! "
    fi

    RESULT=$( printf %s "${RESULT}" | grep ${DB_USER_BHOUND} )
    
    if [ -n "${RESULT}" ]; then
        if [ -n "${1}" ]; then return 1; fi

        echo "The database user '${DB_USER_BHOUND}' already exists ! "
        exit
    fi
    
    echo "Creating a PostgreSQL user & database for Bloodhound... "
    echo "(Password request is for user '${USER_POSTGRES}'.) "
    
    su -c "${DB_CREATE_USER_STR}" - ${USER_POSTGRES}
    su -c "${DB_CREATE_BH_DB_STR}" - ${USER_POSTGRES} 
    
    if [ -n "${1}" ]; then return 0; fi
    exit
}

############################################################################
#
# -c: Create a project database in PostgreSQL for a Bloodhound environment.
# If a parameter is provided, then user error messages are suppressed.
#
Command_Create_Database_for_Project() {
    
    echo "(Password request is for user '${USER_POSTGRES}'.) "
    RESULT=$( su -c "psql -l" - ${USER_POSTGRES} )

    if [ ${?} -ne 0 ]; then
        DisplayCommandFailureErr "Could not execute 'psql' command ! "
    fi

    RESULT=$( printf %s "${RESULT}" | grep ${PROJECT} )
    
    if [ -n "${RESULT}" ]; then
        if [ -n "${1}" ]; then return 1; fi
        
        echo "Database '${PROJECT}' already exists; try dropping it first. "
        exit
    fi

    echo "Attempting to create the PostgreSQL project database... "
    echo "(Password request is for user '${USER_POSTGRES}'.) "
    
    su -c "${DB_CREATE_STR} ${PROJECT}" - ${USER_POSTGRES} 
}

############################################################################
#
# -d: Drop a project database from PostgreSQL.
# If a parameter is provided, then user error messages are suppressed.
#
Command_Drop_Project_Database() {
    
    echo "(Password request is for user '${USER_POSTGRES}'.) "
    RESULT=$( su -c "psql -l" - ${USER_POSTGRES} )

    if [ ${?} -ne 0 ]; then
        DisplayCommandFailureErr "Could not execute 'psql' command ! "
    fi

    RESULT=$( printf %s "${RESULT}" | grep ${PROJECT} )
    
    if [ -z "${RESULT}" ]; then
        if [ -n "${1}" ]; then return 1; fi
        
        echo "Database '${PROJECT}' doesn't exist ! "
        exit
    fi

    echo "Attempting to drop the PostgreSQL project database... "
    echo "(Password request is for user '${USER_POSTGRES}'.) "

    su -c "${DB_DROP_STR} ${PROJECT}" - ${USER_POSTGRES} 
}

############################################################################
#
# -e: Create a Bloodhound project environment.
#
Command_Create_Project_Environment() {
    
    if [ -d ${BLOODHOUND_PROJ_BASE}/${PROJECT} ]; then
        echo "Project '${PROJECT}' already has an environment directory... "

        Get_Yes_No_Defaulted "n" "Do you want to erase & replace it?"

        if [ "${UINPUT}" = "n" ]; then exit ; fi

        rm -rf ${BLOODHOUND_PROJ_BASE}/${PROJECT}
    fi
    
    echo "Attempting to create project environment..."
    echo
    echo "Answer the prompts as they appear for setting up Bloodhound. "
    echo "The first password requested will be for the existing database "
    echo "user named '${DB_USER_BHOUND}', and will NOT be a new password; "
    echo "it must match the password that was previously set for the "
    echo "'${DB_USER_BHOUND}' system account. "
    echo

    INST_CMD="python ${BLOODHOUND_ENV_SETUP_PY}"
    INST_CMD="${INST_CMD} --project=${PROJECT}"
    INST_CMD="${INST_CMD} --environments_directory=${BLOODHOUND_PROJ_BASE}"
    INST_CMD="${INST_CMD} --database-type=${DB_TYPE}"
    INST_CMD="${INST_CMD} --database-name=${PROJECT}"
    INST_CMD="${INST_CMD} --user=${DB_USER_BHOUND}"

    su -c "cd ${INSTALLER_DIR}; ${INST_CMD}" - ${USER_BHOUND}
}

############################################################################
#
# -P: Reconfigure a Bloodhound project environment so that its password 
# digest file is redirected from the project-specific file location to a 
# common file used by all projects.
#
Command_Set_Authentication_Method() {
    
    # First, check to see if the project even has an environment...
    #
    Validate_Project_Directory
    PROJ_BASE="${BLOODHOUND_PROJ_BASE}/${PROJECT}"
    
    # Extract the authentication key value from the 'conf' file:
    #
    Get_Config_File_Value "${PROJ_BASE}/${PROJECT_CONF_FILE}"             \
                    "${CONF_FILE_AUTH_SECTION}" "${CONF_FILE_AUTH_KEY}"
    
    # If we get a "?" as a result, we couldn't parse it, or it's missing 
    # the section for logos... This is a bad thing; let the user fix it.
    #
    if [ "${KEY_VALUE}" = "?" ]; then
    
        echo -n "Could not parse the configuration file in the "
        echo    "'${PROJECT}' Bloodhound environment ! "
        exit ${ERR_FILESYS}
    fi
    
    # Do we need to create the common digest file?
    #
    if [ ! -e "${BLOODHOUND_PROJ_BASE}/${PW_DIGEST_FILE}" ]; then
    
        if [ ! -e "${PROJ_BASE}/${PW_DIGEST_FILE}" ]; then
            DisplayErrBadProjectEnv "Cannot locate the password digest file"
        fi
        
        cp -fp "${PROJ_BASE}/${PW_DIGEST_FILE}" "${BLOODHOUND_PROJ_BASE}/"
        
        if [ ! -e "${PROJ_BASE}/${PW_DIGEST_FILE}" ]; then
            DisplayFileSystemErr "Couldn't create the common htdigest file."
        fi
    fi
    
    # Update the key-value pair to point to the common digest file:
    #
    Set_Config_File_Value "${PROJ_BASE}/${PROJECT_CONF_FILE}"             \
                    "${CONF_FILE_AUTH_SECTION}" "${CONF_FILE_AUTH_KEY}"   \
                    "${BLOODHOUND_PROJ_BASE}/${PW_DIGEST_FILE}"
            
    # Tell the user how to verify that it's working correctly...
    #
    Request_User_Test_Website "login"
}

############################################################################
#
# -t: Test a Bloodhound project environment using the internal Trac server.
#
Command_Test_Project_Environment() {

    Validate_Project_Directory
    
    echo
    echo "Point your browser to 'localhost:${TRACD_PORT}/${PROJECT}' "
    echo "and verify that it presents the '${PROJECT}' wiki page. "
    echo
    echo "Press <Ctrl-C> when finished, to stop the test server... "
    echo
    
    su -c                                                            \
        "tracd --port ${TRACD_PORT} ${BLOODHOUND_PROJ_BASE}/${PROJECT}"   \
        - ${USER_BHOUND}
    echo
}

############################################################################
#
# -s: Deploy a Bloodhound project environment for use with Apache Webserver.
#
Command_Deploy_Project_Web_Site() {
    
    Validate_Project_Directory
    
    PROJECT_DIR="${BLOODHOUND_PROJ_BASE}/${PROJECT}"
    PROJECT_SITE="${PROJECT_DIR}/site"
    
    if [ -d ${PROJECT_SITE} ]; then
        echo "Project '${PROJECT}' already has a site directory... "

        Get_Yes_No_Defaulted "n" "Do you want to erase & replace it?"

        if [ "${UINPUT}" = "n" ]; then exit ; fi

        rm -rf ${PROJECT_SITE}
    fi
    
    echo "Attempting to create project web site directory..."
    
    # Run 'trac-admin' to create the site files...
    #
    su -c \
        "trac-admin ${PROJECT_DIR} deploy ${PROJECT_SITE}" - ${USER_BHOUND}
    
    # ...then install or modify the Apache Virtual Host file accordingly:
    #
    Virtual_Host_File_Add_Project_Stanza

    # Tell the user how to verify that it's working correctly...
    #
    Request_User_Test_Website "login"
    
    echo
    echo "If you get a web page, and can log in (as the Administrator), "
    echo "congratulations -- Your project is set up in Bloodhound! "
}

############################################################################
#
# -L: Insert a Logo file into a Bloodhound project 'site'.
#
Command_Insert_Web_Page_Logo() {
    
    # First, check to see if the project even has an environment...
    #
    Validate_Project_Directory
    PROJ_BASE="${BLOODHOUND_PROJ_BASE}/${PROJECT}"
    
    # Extract the logo file key value from the 'conf' file:
    #
    Get_Config_File_Value "${PROJ_BASE}/${PROJECT_CONF_FILE}"             \
                    "${CONF_FILE_LOGO_SECTION}" "${CONF_FILE_LOGO_KEY}"
    
    # If we get a "?" as a result, we couldn't parse it, or it's missing 
    # the section for logos... This is a bad thing; let the user fix it.
    #
    if [ "${KEY_VALUE}" = "?" ]; then
    
        echo -n "Could not parse the configuration file in the "
        echo    "'${PROJECT}' Bloodhound environment ! "
        exit ${ERR_FILESYS}
    fi
    
    # Display the current logo file, if any, and ask if the user 
    # wishes to add a logo file or replace an existing logo file.
    #
    if [ "${KEY_VALUE}" = "" -o "${KEY_VALUE}" = "*" ]; then
    
        LOGO_FILE=""
        echo "No logo file has been set for '${PROJECT}'. "
    
        Get_Yes_No_Defaulted "y" "Do you want to install a logo file?"
        
    else
        # The key value exists & should be in the form of "site/file"...
        #
        LOGO_FILE=$( basename ${KEY_VALUE} 2>/dev/null )
        
        if [ -e ${PROJ_BASE}/${PROJECT_HTDOCS_DIR}/${LOGO_FILE} ]; then 
    
            echo "'${PROJECT}' is using the logo file: '${LOGO_FILE}'. "
        
            Get_Yes_No_Defaulted "y" "Do you want to replace this file?"
            
        else
            echo "Could not find logo file '${LOGO_FILE}' ! "
        
            Get_Yes_No_Defaulted "y" "Do you want to install a new file?"
        fi
    fi

    # If we're to install a new file, ask the user for the path, 
    # then validate that we actually can find the file specified.
    #
    if [ "${UINPUT}" = "y" ]; then 
        
        echo "Here's what in the 'htdocs' directory for '${PROJECT}': "
        echo "${PROJ_BASE}/${PROJECT_HTDOCS_DIR}/ "
        ls -lF ${PROJ_BASE}/${PROJECT_HTDOCS_DIR}
        echo
        echo "Please enter a path to a logo file for '${PROJECT}'. "
        echo "(Press <ENTER> if you just want to remove it.) "
        read -p "> " LOGO_PATH
        
        # If the user wants to remove all logos, then blank the filename 
        # variable and we're done -- the next 'awk' code will erase it  
        # from the project's 'conf' file; we can leave the file alone.
        # 
        if [ -z "${LOGO_PATH}" ]; then LOGO_FILE=""
            
        # Otherwise, we have to be able to read the file...
        #
        elif [ ! -e ${LOGO_PATH} ]; then
        
            echo "Can't find the file '${LOGO_PATH}' ! "
            exit ${ERR_USER_ABORT}
        
        # And if so, we need to get to work...
        else
            LOGO_FILE=$( basename ${LOGO_PATH} )
            LOGO_PATH=$( dirname ${LOGO_PATH} )
            
            # Check for a degenerate situation: The user selected a logo
            # file that's already installed in the project's folder...
            #
            HTDOCS_DIR=${PROJ_BASE}/${PROJECT_HTDOCS_DIR}
            
            # Only if the path to the file is NOT the path to the file's
            # destination do we need to bother doing anything more...
            #
            if [ "${LOGO_PATH}" != "${HTDOCS_DIR}" ]; then

                # No, they're not the same; Copy to '<site>/htdocs', 
                # but back up an existing file w/ same name.
                #
                if [ -e ${HTDOCS_DIR}/${LOGO_FILE} ]; then
                
                    if [ -e ${HTDOCS_DIR}/${LOGO_FILE}.bak ]; then
                        rm -f ${HTDOCS_DIR}/${LOGO_FILE}.bak
                    fi
                    
                    mv ${HTDOCS_DIR}/${LOGO_FILE}                         \
                            ${HTDOCS_DIR}/${LOGO_FILE}.bak
                fi
                
                # Now we're clear to copy the file into the site folder.
                # Make the owner and permissions match the existing files.
                #
                cp -f ${LOGO_PATH}/${LOGO_FILE} ${HTDOCS_DIR}/${LOGO_FILE}
                chown ${USER_BHOUND}:${USER_BHOUND}                       \
                        ${HTDOCS_DIR}/${LOGO_FILE}
            fi
        fi
    fi
    
    # Now we re-write the project's 'conf' file with the chosen logo 
    # file configuration.  Note that we do this unconditionally: 
    # Even if we're not to change the current configuration, we might 
    # need to fix a corruption in the current file's format.  (We are 
    # a bit forgiving on the format when we read it above.)
    # 
    # Create the file key-value pair string, remembering that Bloodhound
    # records the logo file as being 'site/<logofile>':
    #
    if [ -z "${LOGO_FILE}" ]; then
        LOGO_VALUE=""
    else
        LOGO_VALUE="site/"${LOGO_FILE}
    fi
    
    # Set the new key-value pair in the 'conf' file:
    # 
    Set_Config_File_Value "${PROJ_BASE}/${PROJECT_CONF_FILE}"             \
        "${CONF_FILE_LOGO_SECTION}" "${CONF_FILE_LOGO_KEY}" "${LOGO_VALUE}"
            
    # Tell the user how to verify that it's working correctly...
    #
    if [ "${UINPUT}" = "y" ]; then 
    
        Request_User_Test_Website
    fi
}

############################################################################
#
# -r: Remove a Bloodhound project environment.
#
Command_Remove_Project_Environment() {
    
    if [ ! -d ${BLOODHOUND_PROJ_BASE}/${PROJECT} ]; then
    
        echo "Project '${PROJECT}' does not have an environment ! "
        echo "(Enter '${THIS_SCRIPT} -l' to list the environments.) "
        exit
    fi
    
    Get_Yes_No_Defaulted "n"                                              \
        "Are you sure you want to completely remove project '${PROJECT}'?"

    if [ "${UINPUT}" = "n" ]; then exit ; fi
    
    # Remove the project's site stanza from the Virtual Host file:
    #
    Virtual_Host_File_Remove_Project_Stanza
    
    # Remove the project's Bloodhound environment:
    #
    rm -rf ${BLOODHOUND_PROJ_BASE}/${PROJECT}
    
    # Finally, remove the project's database:
    #
    Command_Drop_Project_Database "quiet"
    
    echo "Completed! "
}

############################################################################
#
# -a: Go through all the steps to create a Bloodhound project.
#
Command_Create_All_for_Project() {
    
    Get_Yes_No_Defaulted "y"                                              \
        "Do you want to create a new Bloodhound environment '${PROJECT}'?"
    if [ "${UINPUT}" = "n" ]; then
        exit
    fi
    
    if [ -d ${BLOODHOUND_PROJ_BASE}/${PROJECT} ]; then
        echo "Project '${PROJECT}' already has an environment directory... "

        Get_Yes_No_Defaulted "n" "Do you want to replace the project?"

        if [ "${UINPUT}" = "n" ]; then exit ; fi

        Command_Remove_Project_Environment
    fi
    
    # Set up the database, including making the Bloodhound user and
    # database, if they don't already exist:
    #
    Create_Pgsql_User "quiet"
    Command_Create_Database_for_Project
    
    # Create the environment:
    #
    Command_Create_Project_Environment

    # Reconfigure the password digest, if desired:
    #
    Get_Yes_No_Defaulted "y"                                              \
        "Do you want to use a common password digest for '${PROJECT}'?"
        
    if [ "${UINPUT}" = "y" ]; then
        Command_Set_Authentication_Method
    fi
    
    # Do a quicky test using the internal web server, if desired:
    #
    Get_Yes_No_Defaulted "y"                                              \
        "Do you want to do a quick test of the project environment?"
        
    if [ "${UINPUT}" = "y" ]; then
        Command_Test_Project_Environment

        echo "Now press <Enter> to deploy the web site..."
        read UINPUT
    fi
    
    # Deploy the Apache web server site files & virtual host file:
    #
    Command_Deploy_Project_Web_Site
}


############################################################################
############################################################################

############################################################################
#
# This is the program:
#
Get_Script_Name

Parse_Command_Line_Args "$@"

if [ -z "${COMMAND}" ]; then
    usage
    exit
fi

Check_Run_As_Root

Validate_Host_Accounts
Validate_Host_Applications
Validate_Host_Databases

case "${COMMAND}" in
    
"CREATE_ALL")  
    Command_Create_All_for_Project
    exit
    ;;
"CREATE_DB")  
    Command_Create_Database_for_Project
    exit
    ;;
"DROP_DB")   
    Command_Drop_Project_Database
    exit
    ;;
"CREATE_ENV")  
    Command_Create_Project_Environment
    exit
    ;;
"AUTH_METHOD")  
    Command_Set_Authentication_Method
    exit
    ;;
"TEST_NEW_ENV")   
    Command_Test_Project_Environment
    exit
    ;;
"DEPLOY_SITE")   
    Command_Deploy_Project_Web_Site
    exit
    ;;
"INSERT_LOGO")   
    Command_Insert_Web_Page_Logo
    exit
    ;;
"REMOVE_ENV")   
    Command_Remove_Project_Environment
    exit
    ;;
*)  
    usage
esac

exit

############################################################################
############################################################################

