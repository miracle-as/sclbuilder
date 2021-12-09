#!/usr/bin/env bash

URL=$1
SCRIPT=/tmp/packagers.sh
echo > $SCRIPT
for REQ in `curl $URL |tr -d ' '|tr -d '\r'`
do
    NAME=`echo $REQ | awk -F'==' '{ print $1 }'`
    VERS=`echo $REQ | awk -F'==' '{ print $2 }'`
    SLUG=`echo ${NAME}___${VERS} | tr '.' '_'`
    EXTRAVAR="'{ \"slug\": \"$SLUG\", \"name\": \"$NAME\", \"version\": \"$VERS\" }'"
    echo ansible-playbook -i inventory sclbuilder_100_insert_package.yml --extra-vars $EXTRAVAR >> $SCRIPT
done


bash $SCRIPT
