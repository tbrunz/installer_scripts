#! /usr/bin/env bash
# Adds bash autocomplete support for 'bd'
_bd()
{
    # Handle spaces in filenames by setting the delimeter to be a newline
    local IFS=$'\n'
    
    # Current argument on the command line
    local CURRENT_PWD=${COMP_WORDS[COMP_CWORD]}
    
    # Available directories to autcomplete to
    local COMPLETIONS=$( pwd | sed 's|/|\n|g' )

    COMPREPLY=( $( compgen -W "${COMPLETIONS}" -- ${CURRENT_PWD} ) )
}
complete -F _bd bd
