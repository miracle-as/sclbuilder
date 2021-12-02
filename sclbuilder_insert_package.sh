#!/usr/bin/env bash

URL=$1
FILENAME="/tmp/upload.requirement.txt"
url $URL > $FILENAME
if [[ $? != 0 ]]
then
    echo "`date`: File not found"
    rm $FILENAME
    exit 1
fi 


if [[ ! -f $FILENAME ]];
then
    echo "`date`: File not found"
    rm $FILENAME
    exit 1
fi 


grep "==" $FILENAME >/dev/null 2>&1
if [[ $? != 0 ]];
then
    echo "`date`: File does not look like at req file"
    rm $FILENAME
    exit 1
fi 



for REQ in `cat $1 |tr -d ' '|tr -d '\r'`
do
    echo $REQ
done


rm $FILENAME