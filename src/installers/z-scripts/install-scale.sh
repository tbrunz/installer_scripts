#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install Pharo "Scale" shell script interpreter
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

USAGE="
Scale is a Linux shell script interpreter that allows shell scripts to be 
written in Smalltalk syntax.  It works by running the scripts in a local 
Pharo image that contains the Scale codebase, using the familiar 'shebang' 
notation at the top of the script:

    #! /usr/bin/env scale

Scripts are provided with a 'system' variable, available in any scale script, 
which is an instance of 'SCSystemFacade'.  This object provides a number of 
useful methods for accessing common shell functions, environment variables, 
stdin/stdout/stderr, sending return codes, etc.  Refer to the web page for 
details.

In addition to the interpreter, the Scale image also provides a GUI that 
allows viewing, editing, and debugging Scale shell scripts (including access 
to the various Pharo browsers to help with coding).  The Scale UI is invoked 
from the command line using

    $ scale-ui <scripts-folder-path>

https://github.com/guillep/Scale
"

POST_INSTALL="
Scale requires a PATH extension to locate the Scale image:

    export PATH=\"\$HOME/.scale/scale:\$PATH\"

or add the following to your '.profile' file:

    # set PATH so it includes 'scale' if it exists
    if [ -d \"\$HOME/.scale\" ] ; then
        PATH=\"\$HOME/.scale/scale:\$PATH\"
    fi

    
To check the installation:
    
    $ scale --version
    Scale 0.1 for Pharo7.0.4
    $ scale --help
    
    Scale - Executing Pharo scripts
    =========================================================

    scale [ options | script-path  [ script-options]  ] 

    [options] 
	    --version	prints the version
	    --help		prints this help 

    [ example ] 
	    $ scale /path/to/script.st  --script-option=1


    Scale-UI (for debugging and code editing)
    =========================================================

    scale-ui [ script-path  [ script-options]  | folder ] 

    [ script-example ] 
	    $ scale-ui /path/to/script.st  --script-option=1

    [ folder-example ]
	    $ scale-ui /path/to/my-script/folder 


There's a lot more information on the website: https://github.com/guillep/Scale

Refer to 'x-special/scale' for example scripts.
"

SET_NAME="Pharo Scale interpreter"
PACKAGE_SET=""

#
# The user must include an 'update' switch (-n or -u)...
#
[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

wget -O- \
    https://raw.githubusercontent.com/guillep/Scale/master/setupScale.sh | bash
    
InstallComplete

