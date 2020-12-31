#!/bin/bash
##
 # Perform resursive AXFR queries to fetch all hostnames of a zone
 #
 # @copyright 2021, Steffen Vogel
 # @license   http://www.gnu.org/licenses/gpl.txt GNU Public License
 # @author    Steffen Vogel <post@steffenvogel.de>
 # @link      http://www.steffenvogel.de
 ##

print_hosts() {
    ZONE=$1; shift 1
    OPTS="$@"

    SUBZONES=""
    HOSTS=""

    IFS=$'\n'
    RECORDS=$(dig +nocmd $ZONE axfr +noall +answer ${OPTS})
    for RECORD in ${RECORDS}; do
        NAME=$(echo ${RECORD}  | tr -s '\t ' '\t' | cut -f1)
        TYPE=$(echo ${RECORD}  | tr -s '\t ' '\t' | cut -f4)

        if [ -z "${NAME}" -o "${NAME}" == *'*'* ]; then
            continue
        fi

        case ${TYPE} in
            NS)            SUBZONES="${SUBZONES} ${NAME}" ;;
            A|AAAA|CNAME)  HOSTS="${NAME} ${HOSTS}" ;;
        esac
    done

    UNIQUE_SUBZONES=$(echo ${SUBZONES} | tr ' ' '\n' | sort -u)
    for SUBZONE in ${UNIQUE_SUBZONES}; do
        if [ ${SUBZONE} != ${ZONE} ]; then
            HOSTS="$(print_hosts ${SUBZONE}) ${HOSTS}"
        fi
    done

    UNIQUE_HOSTS=$(echo ${HOSTS} | tr ' ' '\n' | sort -u)
    for HOST in ${UNIQUE_HOSTS}; do
        echo ${HOST%.}
    done
}

print_hosts $@
