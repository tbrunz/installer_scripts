#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install PlantUML and its dependencies
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

GetOSversion

SET_NAME="PlantUML"
PACKAGE_SET="graphviz  graphviz-doc  "

APP_NAME="plantuml"
#INSTALL_DIR="/usr/local/bin/${APP_NAME}"
INSTALL_DIR="/opt/${APP_NAME}"

SOURCE_DIR="../plantuml"
CheckGlobFilename "basename" "${SOURCE_DIR}" 1 "*.jar"

SYSTEM_LAUNCHER_DIR=/usr/share/applications

USAGE="
PlantUML is an open-source tool allowing users to create UML diagrams from
a plain-text language.  Images can be generated in PNG, in SVG, or in LaTeX
format.  It uses well-formed and human-readable code to render these types 
of UML diagrams:
   Sequence diagram         Usecase diagram        Timing diagram
   Class diagram            Activity diagram       Component diagram
   Object diagram           Deployment diagram     State diagram

The following non-UML diagrams are also supported:
   Wireframe graphical interface        Archimate diagram
   Ditaa diagram                        Gantt diagram
   MindMap diagram                      Work Breakdown Structure diagram
   Entity Relationship diagram
   Specification and Description Language (SDL)
   Mathematic with AsciiMath or JLaTeXMath notation

Diagrams are defined using a simple and intuitive language. (see PlantUML
Language Reference Guide).  http://plantuml.com/en/guide

PlantUML can be used within many other tools; there are various extensions 
or add-ons that incorporate PlantUML:
   * Atom has a community maintained PlantUML syntax highlighter and viewer.
   * Eclipse has a PlantUML plug-in.
   * Google Docs has a 'PlantUML Gizmo' add-on (uses the PlantUML server).
   * LaTeX, using the Tikz package, has limited support for PlantUML.
   * LibreOffice has a 'Libo_PlantUML' extension to use PlantUML diagrams.
   * Microsoft Word can use PlantUML diagrams via a Word Template Add-in.
   * Visual Studio Tools for Office has an add-in called 'PlantUML Gizmo'.
   * Visual Studio Code has a PlantUML plug-in for Microsoft IDE users.

PlantUML is written in Java and uses Graphviz software to lay out its
diagrams.  You will need to visit the PlantUML website to get updates
for its '.jar' file.

http://plantuml.com/download
"

POST_INSTALL="
You may wish to verify that everything has installed and configured correctly.

First, you might wish to add a GraphViz environment variable:

   $ export GRAPHVIZ_DOT=/usr/bin/dot

You can also extend your PATH variable to reduce typing:

   $ PATH=\${PATH}:${INSTALL_DIR}/${APP_NAME}

or add an alias, such as:

   alias puml='java -Xmx1024m -jar ${INSTALL_DIR}/plantuml.jar '
   
after which you can run 'puml' to get the PlantUML GUI.

To run a quick test, open a terminal and enter:

   $ java -jar /opt/plantuml/plantuml.jar -testdot

You can also use this special diagram description in a file 'testdot.txt':

   @startuml
   testdot
   @enduml

then run

   $ java -jar /opt/plantuml/plantuml.jar testdot.txt

and examine the output file, 'testdot.png'.
   
For the Atom editor, recommended packages include

   plantuml-viewer, language-plantuml (save as *.puml)
"

#
# Verify that Java has been installed already:
#
java -version >/dev/null 2>&1

if (( $? > 0 )); then

MSG="${SET_NAME} is dependent on Java, which has not been installed. "

    if [[ -z "${1}" || "${1}" == "-i" ]]; then

        USAGE=$( printf "%s \n \n%s \n \n" "${USAGE}" "${MSG}" )
        set --
    else
        ThrowError "${ERR_MISSING}" "${APP_SCRIPT}" "${MSG}"
    fi
fi

[[ -z "${1}" || "${1}" == "-i" ]] && PerformAppInstallation "$@"

#
# Ensure that the needed files are present in our repo before installing;
#
# Note that on failure, the 'check' routine will throw a warning error &
# return, whereas the 'resolve' routine will throw an error and quit.
# Therefore, if the first fails and the second passes, we must exit manually.
#
CheckGlobFilename "basename" "${SOURCE_DIR}" 1 "*.png"
ICON_CHECK=$?

ResolveGlobFilename "basename" "${SOURCE_DIR}" 1 "*.jar"
(( $ICON_CHECK > 0 )) && exit

PerformAppInstallation "-r" "$@"

#
# Create the installation directory (owned by root) &
# copy files to the installation directory:
#
QualifySudo
makdir "${INSTALL_DIR}"

copy "${SOURCE_DIR}"/* "${INSTALL_DIR}"/

sudo chmod a+rX "${INSTALL_DIR}"/*
sudo chmod a-wx "${INSTALL_DIR}"/*.txt
sudo chmod a-wx "${INSTALL_DIR}"/*.pdf
sudo chmod a-wx "${INSTALL_DIR}"/*.png
sudo chmod a-wx "${INSTALL_DIR}"/*.desktop

SOURCE_GLOB="*.jar"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

JAR_FILE_PATH=${FILE_LIST}
sudo chmod 755 "${JAR_FILE_PATH}"

#
# Copy the .desktop launcher file into place and customize for this app:
#
SOURCE_GLOB="*.desktop"
ResolveGlobFilename "fullpath" "${SOURCE_DIR}" 1 ${SOURCE_GLOB}

APP_LAUNCHER_PATH=${FILE_LIST}

sudo desktop-file-install --dir=${SYSTEM_LAUNCHER_DIR} --mode=644 \
--set-name="${SET_NAME}" \
--set-comment="PlantUML " \
--set-icon="${INSTALL_DIR}/${APP_NAME}.png" \
--set-key="Exec"        \
--set-value="google-chrome http://www.plantuml.com/plantuml" \
--set-key="Terminal"    --set-value="false" \
--set-key="Type"        --set-value="Application" \
--set-key="Categories"  --set-value="Development;" \
${APP_LAUNCHER_PATH}

InstallComplete
