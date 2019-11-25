#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Manage a Bloodhound multi-project setup
# ----------------------------------------------------------------------------
#

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
ERR_PARAMETER=2
ERR_FILESYS=4
ERR_MOUNTING=8
ERR_NO_SUDO=16
ERR_USER_ABORT=32

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
# Get the name of this script (for 'usage' prompts).
#
GetScriptName() {
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
# Display a prompt asking a Yes/No question, repeat until a valid input.
# Allow for a blank input to be defaulted.  Automatically appends "(y/n)"
# to the prompt, capitalized according to the value of DEF_INPUT.
#
# INPUTS:  PROMPT, DEF_INPUT
# OUTPUTS: UINPUT (1 char, lowercase)
#
Get_YesNo_Defaulted() {
    unset UINPUT
    
    if [ $( echo "${DEF_INPUT}" | tr [:upper:] [:lower:] ) = 'y' ]; then
        YES_NO="Y/n"
    else
        YES_NO="y/N"
    fi 
    XPROMPT=${PROMPT}" ("${YES_NO}")"
    
    while [ "${UINPUT}" != "y" -a "${UINPUT}" != "n" ]; do
    
        echo ${XPROMPT}
        read UINPUT
    
        if [ -z "${UINPUT}" ]; then UINPUT="${DEF_INPUT}"; fi
    
        UINPUT=$( echo "${UINPUT}" | cut -c 1 | tr [:upper:] [:lower:] )
    done
}

############################################################################
#
# Verify that the user can obtain sudo privileges; bail if not.
#
CheckSudo() {
    #
    # Simple, silent test to see if 'sudo' has already been obtained.
    # Serves two purposes, as it also gains 'sudo', if eligible.
    #
    sudo ls /root > /dev/null 2>&1
    
    if [ $? != 0 ]; then
        echo -n "${THIS_SCRIPT}: Cannot run this script "
        echo    "without 'sudo' privileges. "
        
        exit ${ERR_NO_SUDO}
    fi
}

############################################################################
#
# Display the script version.
#
DisplayVersion() {
    echo "${THIS_SCRIPT}, version ${VERSION} "
    exit
}

############################################################################
#
# Display the one-line 'usage' prompt.
#
usage() {
    echo -n "usage: ${THIS_SCRIPT} [ -m ] [ [ -g | -d ] <NS user/grp> ] "
    echo "[ -u <NS acct> ] [ -s <NS server #> ] [ -l | -x <local acct> ] "
}

############################################################################
#
# Display the help information (-h).
#
DisplayHelp() {
    echo 
    echo "NAME "
    echo "    ${THIS_SCRIPT} - Manage Bloodhound multi-project setup "
    echo
    echo "SYNOPSIS "
    echo "    ${THIS_SCRIPT} -u "
    echo "    ${THIS_SCRIPT} [ -c | -d ] <project name> "
    echo "    ${THIS_SCRIPT} [ -e | -p | -t | -s ] <project name> "
    echo "    ${THIS_SCRIPT} [ -a ] <project name> "
    echo
    echo "DESCRIPTION "
    echo "    This script does the following: "
    echo "     * Creates a PostgreSQL user for Bloodhound. "
    echo "     * Creates a new PGSQL database for a Bloodhound project. "
    echo "     * Drops a Bloodhound project database from PGSQL. "
    echo "     * Creates a new project environment for Bloodhound. "
    echo "     * Configures a B/H project env to use a common PW digest. "
    echo "     * Tests a new Bloodhound project environment. "
    echo "     * Deploys a Bloodhound project web site for Apache. "
    echo
    echo -n "    Mandatory arguments to long options are mandatory "
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
    echo "    -p --pw-fixup=PROJECT "
    echo "          Use a common password digest for a project "
    echo
    echo "    -t --test=PROJECT "
    echo "          Test a Bloodhound project with the internal web server "
    echo
    echo "    -s --site-deploy=PROJECT "
    echo "          Deploy a Bloodhound project site for use with Apache "
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
    echo "Typical usage: "
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
CheckSwitchHelp() {
    if [[ "${SWITCH}" == "h" || "${CUT_SWITCH}" == "hel" ]]; then
        if [ ${1} -eq 1 ]; then
            DisplayHelp
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
CheckSwitchVersion() {
    if [[ "${SWITCH}" == "v" || "${CUT_SWITCH}" == "ver" ]]; then
        if [ ${1} -eq 1 ]; then
            DisplayVersion
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
CheckSwitchUser() {
    if [[ "${SWITCH}" == "u" || "${CUT_SWITCH}" == "use" ]]; then
        if [ ${1} -eq 1 ]; then
            CreatePgsqlUser
            exit
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
CheckForExclusiveSwitches() {
    
    CheckSwitchHelp ${1}
    CheckSwitchVersion ${1}
    CheckSwitchUser ${1}
}

############################################################################
#
# Parse the command line argument list
#
ParseCommandLineArgs() {    
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
            
            if [ $( echo ${VALUE} | cut -c 1 ) = "-" ]; then 
                DisplayErrParsing_ArgWithLeadHyphen
            fi
            
        # Otherwise we expect to find a switch:
        #
        elif [ $( echo ${TOKEN} | cut -c 1 ) = "-" ]; then 
            
            # Switch: Allow both '-sargument' or '-s argument' forms,
            # and the '--long-name=argument' form.
            #
            SWITCH=$( echo ${TOKEN} | cut -c 2 )
            VALUE=$(  echo ${TOKEN} | cut -c 3- )
            
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
                SWITCH=$( echo ${VALUE} | cut -d '=' -f 1 )
                
                # If there's no '=', then SWITCH got it all; in that
                # case, erase VALUE; otherwise, cut after the '='.
                #
                if [ "${SWITCH}" = "${VALUE}" ]; then VALUE=""
                else
                    VALUE=$(  echo ${VALUE} | cut -d '=' -f 2 )
                fi
                
                # Convert the switch to all lower case, and shorten it.
                #
                SWITCH=$( echo ${SWITCH} | tr [:upper:] [:lower:] )
                CUT_SWITCH=$( echo ${SWITCH} | cut -c -3 )
                
                if [ -z ${VALUE} ]; then
                    #
                    # We can't have a form "--alpha beta"...
                    # But we can have a form "--exclusive"
                    #
                    CheckForExclusiveSwitches ${#}
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
                    SWITCH="p"
                    ;;
                "tes")
                    SWITCH="t"
                    ;;
                "sit")
                    SWITCH="s"
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
        CheckForExclusiveSwitches ${#}
    
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
            p)  
                if [ -z "${COMMAND}" ]; then 
                    COMMAND="PW_FILE_FIXUP"
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
    
        if [ $( echo "uacdepts" | grep "${SWITCH}" ) ]; then
            DisplayErrParsing_DanglingSwitch
        else
            DisplayErrParsing_UnknownSwitch
        fi
    fi
}


############################################################################
############################################################################
#
#  COMMAND EXECUTION
#
############################################################################
############################################################################




############################################################################
############################################################################

############################################################################
#
# This is the program:
#
GetScriptName

ParseCommandLineArgs "$@"

case "${COMMAND}" in
    
"CREATE_ALL")  
    Command_Create_All_for_Project
    ;;
"CREATE_DB")  
    Command_Create_Database_for_Project
    ;;
"DROP_DB")   
    Command_Drop_Project_Database
    ;;
"CREATE_ENV")  
    Command_Create_Project_Environment
    ;;
"PW_FILE_FIXUP")  
    Command_Change_Project_PW_File
    ;;
"TEST_NEW_ENV")   
    Command_Test_Project_Environment
    ;;
"DEPLOY_SITE")   
    Command_Deploy_Project_Web_Site
    ;;
*)  
    DisplayErrParsing_UnknownSwitch
esac

exit

