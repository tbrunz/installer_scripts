#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Query disk SMART test data for one or a range of drives
# ----------------------------------------------------------------------------
#


###############################################################################
#
# Create a list of SMART tests that can be queried for.
# The name of the test is also the text to grep for in 'smartctl'
# output, so spelling and case are essential here.
#
# This list can be modified, as needed.  Obtain a list of test names
# by running 'sudo smartctl -x /dev/sda'.  The last should be <cancel>.
#
SMART_TESTS=(
   "SMART Health Status"
   "SMART overall-health"
   "Spin_Up_Time"
   "Reallocated_Sector_Ct"
   "Power_On_Hours"
   "Spin_Retry_Count"
   "Runtime_Bad_Block"
   "Reported_Uncorrect"
   "Current_Pending_Sector"
   "Offline_Uncorrectable"
   "<cancel>"
)


###############################################################################
#
# Select which SMART test to query for.  In this case, create a menu
# and display on the console for the operator to choose from.
# The name of the test is also the text to grep for in 'smartctl' output.
#
Select_Test_Type () {
   echo
   echo "Please select one of the following SMART tests to query: "

   select TEST_TYPE in "${SMART_TESTS[@]}"; do

      [[ -n "${TEST_TYPE}" ]] && break

      echo "Just pick one of the listed tests, okay? "
   done

   if [[ "${TEST_TYPE}" == "<cancel>" ]]; then
      echo 1>&2 "cancelling ... "
      exit 2
   fi
}


###############################################################################
#
# Get a list of 'sd' devices in '/dev' and collect their drive letter
# suffixes in an array, forming an (ordered) list of local drive letters.
#
Get_My_Drives () {
   LOCAL_DRIVES=()
   LAST_INDEX=0
   local DRIVE

   while read DRIVE; do
      LOCAL_DRIVES+=( "${DRIVE}" )

   done < <( ls /dev/* | egrep -o 'sd[[:alpha:]]+' | cut -c 3- | sort | uniq )

   MY_FIRST=${LOCAL_DRIVES[0]}

   LAST_INDEX=$(( ${#LOCAL_DRIVES[@]} - 1 ))

   MY_LAST=${LOCAL_DRIVES[ ${LAST_INDEX} ]}
}


###############################################################################
#
# Given 1 or 2 drive letters (which can be letter strings), search the
# list of local drives to find their respective list indices.
#
Get_Drive_List () {
   local FIRST=${1}
   shift
   local LAST=${1}

   FIRST_LIST_IDX=
   LAST_LIST_IDX=

   for (( IDX=0; IDX<=LAST_INDEX; IDX++ )); do

      if [[ "${LOCAL_DRIVES[ ${IDX} ]}" == "${FIRST}" ]]; then
         FIRST_LIST_IDX=${IDX}
      fi

      if [[ "${LOCAL_DRIVES[ ${IDX} ]}" == "${LAST}" ]]; then
         LAST_LIST_IDX=${IDX}
         return
      fi
   done
}


###############################################################################
#
# This is the main function, which gets the list of local drives,
# gets a range of drives to check, gets a SMART test type to query for,
# and checks the drives in the range.
#
Check_My_Drives () {
   FIRST_DRIVE=${1}
   shift
   LAST_DRIVE=${1}

   Get_My_Drives

   [[ -n "${FIRST_DRIVE}" ]] || FIRST_DRIVE=${MY_FIRST}
   [[ -n "${LAST_DRIVE}" ]] || LAST_DRIVE=${MY_LAST}

   Get_Drive_List "${FIRST_DRIVE}" "${LAST_DRIVE}"

   if [[ ! ${FIRST_LIST_IDX} ]]; then
      echo 1>&2 "error: could not find a first drive for '${FIRST_DRIVE}' "
      exit 1
   fi

   if [[ ! ${LAST_LIST_IDX} ]]; then
      echo 1>&2 "error: could not find a last drive for '${LAST_DRIVE}' "
      exit 1
   fi

   Select_Test_Type

   echo "SMART '${TEST_TYPE}' results for {${FIRST_DRIVE}..${LAST_DRIVE}}:"

   for (( IDX=FIRST_LIST_IDX; IDX<=LAST_LIST_IDX; IDX++ )); do

      DRIVE_LETTER=${LOCAL_DRIVES[ ${IDX} ]}

      sudo smartctl -x /dev/sd${DRIVE_LETTER} | \
      egrep "${TEST_TYPE}" | \
      awk \
         -v TestType="${TEST_TYPE}" \
         -v Drive="${DRIVE_LETTER}" \
         '{ printf("/dev/sd%s = %s \n", Drive, $NF) }'
   done
   echo
}


###############################################################################
#
# Check for a switch argument; Since we don't have any options,
# any switch will be interpreted as '-h' (help).
#
if [[ "${1:0:1}" == "-" ]]; then
   echo 1>&2 "usage: ${0} [start drive letter [end drive letter]] "
   exit
fi

# Do the SMART query.
#
Check_My_Drives "${@}"

###############################################################################
