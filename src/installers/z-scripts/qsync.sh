#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Synchronize a subset of the installer repo to the localhost
# ----------------------------------------------------------------------------
#

LOCAL_DIR=~/linux
CHROMEOS_DIR=${LOCAL_DIR}/chromeos
EXCLUDES_FILE=${CHROMEOS_DIR}/chromeos-repo-excludes

REMOTE_ACCT=ted
REMOTE_HOST=cricket
REMOTE_DIR=alin

cd "${LOCAL_DIR}"
if (( $? != 0 )); then
	echo "Can't find the local repo directory ! "
	exit 1
fi

RSYNC_OPTS="${*}"

if [[ "${RSYNC_OPTS}" == "-N" ]]; then
	RSYNC_OPTS="-n | grep -v '/$' | less"
fi

SYNC_CMD="rsync -auvxP --delete --exclude-from=${EXCLUDES_FILE}"
SYNC_CMD="${SYNC_CMD} ${REMOTE_ACCT}@${REMOTE_HOST}:${REMOTE_DIR}/"
SYNC_CMD="${SYNC_CMD} ./ ${RSYNC_OPTS}"

bash -c "${SYNC_CMD}"
