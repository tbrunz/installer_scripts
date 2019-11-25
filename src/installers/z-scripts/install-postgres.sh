#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Install PostgreSQL database
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
PostgreSQL (or Postgres) is an object-relational database management
system (ORDBMS) available for many platforms including Linux, FreeBSD,
Solaris, Microsoft Windows, and Mac OS X.  It is released under the
PostgreSQL License, an MIT-style license, and is thus free and open
source software.

PostgreSQL is developed by the PostgreSQL Global Development Group,
consisting of a handful of volunteers employed and supervised by
companies such as Red Hat and EnterpriseDB.  It implements the majority
of the SQL:2008 standard, is ACID-compliant, is fully transactional
(including all DDL statements), has extensible data types, operators,
index methods, functions, aggregates, procedural languages, and has a
large number of extensions written by third parties.

The vast majority of Linux distributions have PostgreSQL available in
supplied packages.  Mac OS X, starting with Lion, has PostgreSQL server
as its standard default database in the server edition, and PostgreSQL
client tools in the desktop edition.
"

SET_NAME="PostgreSQL Database"
PACKAGE_SET="postgresql  postgresql-doc  postgresql-contrib  pgadmin3  "
PACKAGE_SET="${PACKAGE_SET} uuid oidentd libdbd-pg-perl  "

PerformAppInstallation "$@"
