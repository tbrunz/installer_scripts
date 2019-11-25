#! /usr/bin/env bash
#

# Restrict where this script can be run (so we don't screw up the FS).
#
REQPWD="Downloads/linux"

FOLDER0=$( basename $( pwd ) )
FOLDER1=$( basename $( dirname $( pwd ) ) )

PWD="${FOLDER1}/${FOLDER0}"

if [[ "${PWD}" != "${REQPWD}" ]]; then

   echo >&2 "Can't run here; 'pwd' must be '${REQPWD}'... "
   exit 1
fi

# Update the scripts folder -- make one if missing.
#
mkdir -p ./z-scripts

rsync -auvxP --delete --exclude=deprecated --exclude=alternatives --exclude=all-need-rework ~/ascr/ ./z-scripts/

# Can't do anything else without arguments...
#
[[ -n "${@}" ]] || exit 

# Treat each argument as a directory name to sync.
#
for PKG in "${@}"; do

   PKG=$( basename "${PKG}" )

   if [[ ! -d ./"${PKG}" ]]; then
   
      echo >&2 "Um, '${PKG}' is not a directory here... "
      exit 1
   fi
   
   if [[ ! -d ~/alin/"${PKG}" ]]; then
      if [[ "${PKG}" != "Z-FILES" ]]; then
         echo >&2 "Um, '${PKG}' is not a directory in the installer repo... "
         exit 1
      fi
         
      rsync -auvxP --delete --exclude=archive ~/a64/"${PKG}"/ ./"${PKG}"/
      exit $?
   fi
   
   rsync -auvxP --delete --exclude=archive ~/alin/"${PKG}"/ ./"${PKG}"/

done

