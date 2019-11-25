#! /usr/bin/env bash
#
WITH_HOOKS=$( ls -1 */hooks/pre-commit | egrep -o ^[^/]+ )

ALL_REPOS=$( ls -1 */hooks/post-commit | egrep -o ^[^/]+ )

NEEDS_HOOK=( )

for REPO in ${ALL_REPOS}; do

	RESULT=$( printf %s ${WITH_HOOKS} | grep ${REPO} )

	if [[ -z "${RESULT}" ]]; then

		NEEDS_HOOK+=( ${REPO}  )

	fi
done

if (( ${#NEEDS_HOOK[@]} == 0 )); then

	echo "No repo needs fixing up ! "
	exit
fi

echo "Fixing up the following: "

for REPO in "${NEEDS_HOOK[@]}"; do

	cp -v pre-commit ${REPO}/hooks/

	chown ubersvn:ubersvn ${REPO}/hooks/*
done

echo "Done ! "

