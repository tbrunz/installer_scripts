#! /usr/bin/env bash

# Invoke with $ getopt.sh to|from DEST [-d] [-p PORT] [-n] [-- RSYNC_OPTS]

echo "DIR = '${1}'"
shift

echo "DEST = '${1}'"
shift

getopts "dp:n" THISOPT 

if (( $? == 0 )); then
    echo -n "Success: "
    SHIFTVAL=${OPTIND}
else
    echo -n "Failure: "
fi

echo "THISOPT = '${THISOPT}', OPTIND = '${OPTIND}', OPTARG = '${OPTARG}' "


getopts "dp:n" THISOPT 

if (( $? == 0 )); then
    echo -n "Success: "
    SHIFTVAL=${OPTIND}
else
    echo -n "Failure: "
fi

echo "THISOPT = '${THISOPT}', OPTIND = '${OPTIND}', OPTARG = '${OPTARG}' "


getopts "dp:n" THISOPT 

if (( $? == 0 )); then
    echo -n "Success: "
    SHIFTVAL=${OPTIND}
else
    echo -n "Failure: "
fi

echo "THISOPT = '${THISOPT}', OPTIND = '${OPTIND}', OPTARG = '${OPTARG}' "

shift $(( SHIFTVAL - 1 ))

echo "$1 $2 $3"


