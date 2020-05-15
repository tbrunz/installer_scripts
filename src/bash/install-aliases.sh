#! /usr/bin/env bash
#
HOSTS=${1,,}
HOSTS=${1##-}

echo ">>> cp bash_aliases ~/.bash_aliases "
cp bash_aliases ~/.bash_aliases

if [[ "${HOSTS:0:1}" == "h" ]]; then
    echo ">>> cp bash_hosts ~/.bash_hosts "
    cp bash_hosts ~/.bash_hosts
fi

echo 
echo "Execute ' . ~/.bash_aliases ' to apply... "

