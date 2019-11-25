#! /usr/bin/env bash
#
# ----------------------------------------------------------------------------
# Toggle whether or not the host will respond to ICMP echo requests
# ----------------------------------------------------------------------------
#

KERNEL_PROCESS=/proc/sys/net/ipv4/icmp_echo_ignore_all

STATE=$( cat ${KERNEL_PROCESS} )
        
CMD=$( printf %s "${1}" | tr [:upper:] [:lower:] )

if [[ -n ${STATE} ]]; then

    if [[ -z "${CMD}" ]]; then

        case ${STATE} in
        0)
            REPLY="does"
            ;;
        1)
            REPLY="does NOT"
            ;;
        *)
            echo "error: Cannot parse the kernel state: '${REPLY}' ! "
            exit 1
        esac

        echo "Kernel "${REPLY}" answer ICMP Echo requests"
        exit
    fi

    case ${CMD} in

    1|"y"|"t"|"on"|"yes"|"true")
        echo 0 > ${KERNEL_PROCESS}
        (( $? != 0 )) && exit 2
        echo "Kernel now answers ICMP Echo requests"
        ;;

    0|"n"|"f"|"off"|"no"|"false")
        echo 1 > ${KERNEL_PROCESS}
        (( $? != 0 )) && exit 2
        echo "Kernel will no longer answer ICMP Echo requests"
        ;;
    *)
        echo "error: bad argument "
        exit 1
        ;;
    esac

else
    echo "error: Cannot locate '${KERNEL_PROCESS}' ! "
    exit 1
fi

