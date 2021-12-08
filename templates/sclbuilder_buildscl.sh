#!/usr/bin/env bash

CMD=$0
PACKAGE=$1
PERSIST=$2

source /usr/local/bin/setbuildenv.sh

usage ()
{
echo "usage $CMD"
echo $1
exit 0
}

check_args ()
{
if [[ $PACKAGE == "" ]];
then
	usage "Package missing"
fi
}

logme ()
{
if [[ $QUIET != "yes" ]];
then
	TEXT=`echo $1 | tr ' ' '¤'`
	TS=`date |tr ' ' '¤'`
	printf "%-20s : %-32s %s \n" $TS $PACKAGE  $TEXT |tr '¤' ' '
fi

}

lastbuild ()
{
	curl http://repos.pip2scl.dk/header.html >  $INDEX
	echo "<pre>" >> $INDEX
	cat $LASTBUILD >> $INDEX
	echo "</pre>" >> $INDEX
	curl http://repos.pip2scl.dk/footer.html >> $INDEX
	scp $INDEX root@repos.pip2scl.dk:/usr/share/nginx/html/index.html 
}

build_scl ()
{
	logme "adding $PACKAGE to software collection $SCL"
	wget  $OURURL -O $OURSOURCE  >/dev/null 2>&1
	if [[ $? == 0 ]];
	then	
		logme "Download complete"
	else	
		logme "Download Fauild"
		exit	
	fi
	NAMEINTAR=`tar tvf $OURSOURCE |head -1 |awk '{ print $6 }' |sed 's(/(('`
	wget -O $VERSPECFILE   $VERSPECFILEURL >/dev/null 2>&1
	logme "Create spec file"
	spec2scl  $VERSPECFILE > $PRESCLFILE  2>/dev/null
	logme "Our SCL specfile before mod is i$PRESCLFILE"
	AFTERLINE=`cat $PRESCLFILE | grep "python3 setup.py install" -A1 | tail -1`
	echo "$AFTERLINE"  |grep '%{?scl:EOF}' >/dev/null 2>&1
	if [[ $? == 0 ]];
	then
		logme "We need to append this line in the the scl spec file after python setup and before scl"
		grep "python3 setup.py install" -B1000000 $PRESCLFILE >/tmp/header
		grep "python3 setup.py install" -A1000000 $PRESCLFILE | grep -v "python3 setup.py install" >/tmp/footer
	fi
       	sed -i 's#root=$RPM_BUILD_ROOT#root=$RPM_BUILD_ROOT/opt/{{ organisation }}/{{ organisation }}-{{ project }}/root#'  $PRESCLFILE
       	sed -i "s#%setup.*#%setup -n ${NAMEINTAR}#" $PRESCLFILE
	logme "mandatory_after_setup.sh $PRESCLFILE"

	mandatory_after_setup.sh $PRESCLFILE > $PRESCLFILE.added
	if [[ $? == 0 ]];
	then
		logme "We have added the mandatory part"
		cp $PRESCLFILE.added $PRESCLFILE
	else
		logme "Add failed"
		exit 0

	fi

##################################
#
####################################
       	if [[ $PACKAGE == "pyOpenSSL==19.1.0" ]];
      		then
		logme "hack require"
		sed -i "s/BuildRequires: %{?scl_prefix}openssl-devel %{?scl_prefix}python3-devel %{?scl_prefix}python3-sphinx/BuildRequires: openssl-devel python3-devel python3-sphinx/" $PRESCLFILE
	
	fi

##################################
#
####################################
       	if [[ $PACKAGE == "xmlsec==1.3.3" ]];
       	then
		logme "hack require"
		sed -i "s/BuildRequires: %{?scl_prefix}pkg-config %{?scl_prefix}xmlsec1-devel %{?scl_prefix}libxml2-devel %{?scl_prefix}xmlsec1-openssl-devel/BuildRequires: pkg-config xmlsec1-devel libxml2-devel xmlsec1-openssl-devel/" $PRESCLFILE
	
	fi	

##################################
#
####################################
   	if [[ $PACKAGE == "Django==2.2.16" ]];
   	then
		logme "DJango hack"
 	      # Sort the filelist so that directories appear before files. This avoids
 	      # Make sure we match foo.pyo and foo.pyc along with foo.py (but only once each)
    	grep -P "Sort the filelist so that directories appear before files. This avoids" $PRESCLFILE -B100000 |grep -v "Sort the filelist so that directories appear before files. This avoids" > PART1
	    echo 'sed -i "s(//(/(" INSTALLED_FILES' >> PART1
	    grep -P "^EOF$" $PRESCLFILE -A100000 |grep -v "^EOF$" > PART2
	    cat PART1 PART2 |grep -v " DIRS FILES" |grep -v /usr/share/man/man1/django-admin.1.gz  |grep  -v '%doc' > $PRESCLFILE
    fi

##################################
#
####################################
    if [[ $PACKAGE == "uWSGI==2.0.18" ]];
    then
	  	sed -i 's#"/usr/bin/uwsgi"##' $PRESCLFILE
	  	echo "/opt/miracle/miracle-awx/root/usr/bin/uwsgi" >> $PRESCLFILE
    	echo "/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin/uwsgi-2.0.18-1.x86_64.debug" >> $PRESCLFILE
    fi

    ##################################
    #
    ####################################
    if [[ $PACKAGE == "ruamel.yaml.clib==0.2.0" ]];
    then
  		sed -i 's#"/usr/bin/uwsgi"##' $PRESCLFILE
	  	echo "/opt/miracle/miracle-awx/root/usr/bin/uwsgi" >> $PRESCLFILE
      	echo "/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin/uwsgi-2.0.18-1.x86_64.debug" >> $PRESCLFILE
    fi

    ##################################
    #
    ####################################
    if [[ $PACKAGE == "ruamel.yaml.clib==0.2.0" ]];
	then	
		echo 'mkdir -p /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/opt/miracle/miracle-awx/root/usr/bin' >$PRESCLFILE.ruamel.yaml.clib-0.2.0.add
		echo 'touch /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/opt/miracle/miracle-awx/root/usr/bin/uwsgi' >> $PRESCLFILE.ruamel.yaml.clib-0.2.0.add
		echo 'mkdir -p /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin' >>$PRESCLFILE.ruamel.yaml.clib-0.2.0.add
		echo 'touch /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin/uwsgi-2.0.18-1.x86_64.debug' >>$PRESCLFILE.ruamel.yaml.clib-0.2.0.add
	   	/usr/local/bin/mergefiles.sh ${PRESCLFILE}  ${PRESCLFILE}.ruamel.yaml.clib-0.2.0.add "%clean" before   >/dev/null 2>&1
	fi



    #################################
    #
    ####################################
	if [[ $PACKAGE == "ruamel.yaml==0.16.10" ]];
	then
		echo "/usr/lib/python3.6/site-packages/ruamel/yaml/LICENSE"  >> $PRESCLFILE
	fi

    ##################################
    #
    ####################################
    if [[ $PACKAGE == "jaraco.text==3.2.0" ]]
    then
      	logme "Hack. add files"
  		echo 'mkdir -p "/root/rpmbuild/BUILDROOT/miracle-awx-jaraco.text-3.2.0-1.x86_64/usr/lib/python3.6/site-packages/jaraco/text" ' >  $PRESCLFILE.add
   		echo 'touch "/root/rpmbuild/BUILDROOT/miracle-awx-jaraco.text-3.2.0-1.x86_64/usr/lib/python3.6/site-packages/jaraco/text/Lorem ipsum.txt" ' >>  $PRESCLFILE.add
   		/usr/local/bin/mergefiles.sh ${PRESCLFILE}  ${PRESCLFILE}.add "%clean" before   >/dev/null 2>&1
       	echo '"/opt/miracle/miracle-awx/root/usr/lib/python3.6/site-packages/jaraco/text/Lorem ipsum.txt"' >> $PRESCLFILE
    fi

	logme "rpmbuild -ba -D 'debug_package %{nil}' --clean $PRESCLFILE --define \"scl {{ organisation }}-{{ project }}\" "
	rpmbuild -ba -D 'debug_package %{nil}' --clean $PRESCLFILE --define "scl miracle-awx" >/tmp/prebuild.log 2>&1
	grep "Wrote:" /tmp/prebuild.log >/tmp/${NAME}-${VERSION}.sclfiles
	if [[ $? == 0 ]];
	then
		logme "scl build succeeded"
		scp  /tmp/${NAME}-${VERSION}.sclfiles root@repos.pip2scl.dk:/usr/share/nginx/html/META/${NAME}-${VERSION}.sclfiles
		cp $PRESCLFILE $SCLFILE
		for FILE in  `cat  /tmp/prebuild.log |grep "^Wrote:"   |awk '{ print $2 }'`
		do
			logme "$FILE created"
		done
		if [[ $PERSIST == '-persist=yes' ]];
		then

              		scp $SCLFILE root@repos.pip2scl.dk:/usr/share/nginx/html/SPECS/${NAME}-${VERSION}.hardcoded.scl.spec  >/dev/null 2>&1
                	if [[ $? == 0 ]];
                	then
                        	logme "scl specfile copied"
                	else
                        	logme "scl specfile copied"
                        	exit
                	fi
		fi

		scp $SCLFILE root@repos.pip2scl.dk:/usr/share/nginx/html/SPECS/	 >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "scl specfile copied"
		else
			logme "scl specfile copied"
			exit
		fi

		rsync -avzc $BUILDDIR/RPMS/* root@repos.pip2scl.dk:/usr/share/nginx/html/RPMS/ >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "scl rpm synced"
		else
			logme "scl rpm sync failed"
			exit
		fi

		rsync -avzc $BUILDDIR/SRPMS/* root@repos.pip2scl.dk:/usr/share/nginx/html/SRPMS/ >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "scl srpm synced"
			
		else
			logme "scl srpm sync failed"
			exit
		fi
	else
		logme "scl build failed in $NAME $VERSION"
	fi
	
}
	

check_args
logme "$PACKAGE"
LOOP=1
build_scl
logme "scl build ende