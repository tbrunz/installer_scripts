#! /usr/bin/env bash
#

bd() {
    local OLD_PWD=$( pwd )
    local NEW_PWD=

    local PATH_DIR=

    local OPTIONS=""
    local E_SET=
    local I_SET=

    local ERR=

    #
    # No positional parameters?  Error: return the usage prompt
    #
    (( $# == 0 )) && ERR=true

    #
    # While there are arguments on the CLI, parse them:
    #
    while [[ -n "${1}" ]]; do

        getopts ":ei" SWITCH
        
        if (( $? != 0 )); then
            
            # If not a switch, then it MUST be a directory path element
            #
            if [[ -z "${PATH_DIR}" ]]; then 
                PATH_DIR=${1}
                shift
                OPTIND=1
            else
                # However, a second non-switch is a screw-up:
                ERR=true
                shift
                OPTIND=1
            fi
            
        elif [[ ${SWITCH} == "?" ]]; then
            
            # It's a switch, but it's not one we recognize...
            #
            ERR=true
            shift
            OPTIND=1
        else
            case ${SWITCH} in
            "e")
                [[ ${E_SET} ]] || OPTIONS=${OPTIONS}"e"
                E_SET=true
                ;;
            "i")
                [[ ${I_SET} ]] || OPTIONS=${OPTIONS}"i"
                I_SET=true
                ;;
            *)
                echo 1>&2 "error: Internal error parsing the CLI ! "
                exit 1
                ;;
            esac
            shift
            OPTIND=1
        fi
    done

    # 
    # Any errors encountered while parsing the cmd line get a usage prompt:
    #
    if [[ -z "${PATH_DIR}" || ${ERR} ]]; then 
        cat << USAGE

usage: ${FUNCNAME} [-e] [-i] <pwd_dir_ref>

Go back to a specified directory in the pwd hierarchy.
Allows partial completion and combined forms such as 
$ ls \`${FUNCNAME} <dir_ref>\`

https://github.com/vigneshwaranr/bd

USAGE

        return
    fi

    #
    # Based on the switches, determine the new directory path:
    #
    case ${OPTIONS} in
    'ei' | 'ie' )
        # Allow a full-word specification with case-insensitivity
        NEW_PWD=$( printf "%s" ${OLD_PWD} | \
                perl -pe 's|(.*/'${PATH_DIR}'/).*|$1|i' )
        ;;
    'e' )
        # Require full-word specification with case-sensitivity
        NEW_PWD=$( printf "%s" ${OLD_PWD} | \
                sed 's|\(.*/'${PATH_DIR}'/\).*|\1|' )
        ;;
    'i' )
        # Allow a partial-word specification with case-insensitivity
        NEW_PWD=$( printf "%s" ${OLD_PWD} | \
                perl -pe 's|(.*/'${PATH_DIR}'[^/]*/).*|$1|i' )
        ;;
    * )
        # Allow a partial-word specification with case-sensitivity
        NEW_PWD=$( printf "%s" ${OLD_PWD} | \
                sed 's|\(.*/'${PATH_DIR}'[^/]*/\).*|\1|' )
        ;;
    esac

    #
    # What did we get?  
    #
    if [[ "$NEW_PWD" == "${OLD_PWD}" ]]; then 
        echo "No prior occurrence "
    else
        echo ${NEW_PWD}
        cd "${NEW_PWD}"
    fi

    #unset NEW_PWD
}

###############################################################################

