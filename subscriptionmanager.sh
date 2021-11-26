#!/usr/bin/env bash

#Set the ofline token
#https://access.redhat.com/management/api <---- Create it here

if [[ -f offline.token ]];
then 
	offline_token=`cat offline.token`
else
	echo "Please provide offline access token"
	
	echo "Get it here ---> https://access.redhat.com/management/api <---- "
	echo ""
	exit 12

fi

#Connect and get the access token
curl https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token 
curl https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token > access.token 2>/dev/null
access_token=`cat access.token |jq '.access_token'|tr -d '"'`

echo $access_token


curl -H "Authorization: Bearer $access_token" "https://api.access.redhat.com/management/v1/subscriptions"  >subscriptions.json 2>/dev/null
curl -H "Authorization: Bearer $access_token" "https://api.access.redhat.com/management/v1/systems"  >systems.json 2>/dev/null
# leave benny and delete the rest :-) 


cat systems.json 
for UUID in `cat systems.json  |jq '.body[] | "\(.name) \(.uuid)"'|tr -d '"'|grep -vf  ignore.systems |awk '{ print $2 }'`
do
	echo "`date`: Delete system : $UUID"
	curl -H "Authorization: Bearer $access_token" -X DELETE "https://api.access.redhat.com/management/v1/systems/${UUID}"  
done


