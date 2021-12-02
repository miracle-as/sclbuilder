#!/usr/bin/env bash

URL=$1

for REQ in `cat $URL |tr -d ' '|tr -d '\r'`
do
    echo $REQ
done


rm $FILENAME