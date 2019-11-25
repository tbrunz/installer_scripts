#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install 'geany' IDE/editor using the Ubuntu repository.
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
Geany is a lightweight GUI text editor that includes basic IDE features. It
is based on Scintilla and GTK+, and is designed to have short load times
with limited dependency on separate packages or external libraries on Linux.
It has been ported to a wide range of operating systems, such as BSD, Linux,
macOS, Solaris, and Windows. Among the supported programming languages and
markup languages are C, C++, C#, Java, JavaScript, PHP, HTML, LaTeX, CSS,
Python, Perl, Ruby, Pascal, Haskell, Erlang, Vala, and many others.

In contrast to traditional Unix-based editors like Emacs or Vim, Geany more
closely resembles programming editors common on Microsoft Windows such as
Programmer's Notepad or Notepad++, both of which also use Scintilla.

For more information, see https://www.geany.org
"

SET_NAME="geany"
PACKAGE_SET="geany  "

PerformAppInstallation "$@"
