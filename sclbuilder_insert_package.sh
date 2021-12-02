#!/usr/bin/env bash

URL=$1

for REQ in `curl $URL |tr -d ' '|tr -d '\r'`
do
    NAME=`echo $REQ | awk -F'==' '{ print $1 }'`
    VERS=`echo $REQ | awk -F'==' '{ print $2 }'`
    ansible-playbook -i inventory sclbuilder_insert_package.yml --extra-vars {' "slug": "$REQ", "name": "$NAME", "version": "$VERS" }'
done
