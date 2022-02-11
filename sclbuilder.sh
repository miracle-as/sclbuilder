#!/usr/bin/env bash

CMD=$0
PACKAGE=$1
PERSIST=$2

NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
SCL=$2
QUIET="no"
BUILDDIR="/root/rpmbuild"
BUILDOUT="$BUILDDIR/OUTPUT"
BUILDOUT="$BUILDDIR/OUTPUT"
AUTOPATCHDIR="$BUILDDIR/AUTOPATCH"
mkdir $AUTOPATCHDIR >/dev/null 2>&1 || touch AUTOPATCHDIR
MYAUTOPATCH="autopath:$AUTOPATCHDIR/$NAME-$VERSION.patch.sh"
AUTOPATCH="$AUTOPATCHDIR/$NAME-$VERSION.patch.sh"
FAILEDRPMS="$BUILDDIR/OUTPUT/failed.txt"
mkdir $BUILDOUT >/dev/null 2>&1 || touch $BUILDOUT
touch $FAILEDRPMS
MYCRC="crc:$PACKAGE"
MYEXT="ext:${PACKAGE}"
MYDIRKEY="pkgdir:${PACKAGE}"
MYKEY="filename:${PACKAGE}"
MYRPM="rpm:${PACKAGE}"
MYSPEC="specfile:${PACKAGE}"
MYVERSPEC="verifiedspecfile:${PACKAGE}"
MYRPMSPEC="specfile:RPM:${PACKAGE}"
MYSRPM="rpms:${PACKAGE}"
MYSUM="sum:${PACKAGE}"
MYURL="url:${PACKAGE}"
MYSRCNAME="sourcefilename:${PACKAGE}"
MYERR="error:{$PACKAGE}"
MYNIT="NIT:${PACKAGE}"
NIT=""
PYCMD="python3"
PRETTYSPEC="/usr/local/bin/prettyspec.sh"
EXTENTION=""
FILE=""
LASTBUILD="${BUILDDIR}/OUTPUT/${NAME}-${VERSION}.build.log
INDEX="${BUILDDIR}/OUTPUT/${NAME}-${VERSION}.build.html


usage ()
{
echo "usage $CMD"
echo $1
exit 1
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



tgz2tgz ()
{
	logme "tar gz file to tar gz"
}



zip2tgz ()
{
	logme "Zip to tgz"
        OURNAME="${NAME}-${VERSION}.tar.gz"
	SRCFILE=`redis-cli get $MYSRCNAME`
        logme "Repacking $SRCFILE"
        logme "clean /tmp/repack"
        /usr/bin/rm -r /tmp/repack >/dev/null 2>&1
        logme "create a repack dir"
        mkdir /tmp/repack >/dev/null 2>&1
        logme "Jump in to zip repack dir"
        cd /tmp/repack
	cp $BUILDDIR/DOWNLOADS/$SRCFILE /tmp/repack.zip >/dev/null 2>&1

	logme "File copied to tmp"
	unzip /tmp/repack.zip >/dev/null 2>&1
	if [[ $? == 0 ]];
	then
		logme "file unzipped"
	else
		logme "unzip failed"
		exit
	fi
	NEWNAMEINTAR=`ls -1`
	logme "name i archive is $NEWNAMEINTAR"
	logme "touch files thar we really need"
        touch ${NEWNAMEINTAR}/README.md
        touch ${NEWNAMEINTAR}/CHANGELOG.rst
        tar czf ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.tar.gz $NEWNAMEINTAR 
	if [[ $? == 0 ]];
	then
		logme "file repacked as ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.tar.gz "
	else
		logme "repacking failed"
		exit
	fi
        logme "Uploading repacked tar"
        scp ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.tar.gz   root@repos.pip2scl.dk:/usr/share/nginx/html/SOURCES/${OURNAME}  >/dev/null 2>&1
        logme "clean /tmp/repack"
        OURURL="http://repos.pip2scl.dk/SOURCES/${OURNAME}"
        redis-cli set $MYURL "$OURURL"  >/dev/null 2>&1
        redis-cli set $MYEXT "tar.gz"  >/dev/null 2>&1
        logme "$PACKAGE Package converted to tgz"
        /usr/bin/rm -r /tmp/repack >/dev/null 2>&1

}


bz2tgz ()
{
	logme "bzip to tgz"
	MYURL="url:${PACKAGE}"
        EXTENTION="tar.gz"
        OURNAME="${NAME}-${VERSION}.${EXTENTION}"
        URL=`redis-cli get $MYURL`
        wget $URL -O /tmp/bzfile.bz2 >/dev/null 2>&1
	/usr/bin/rm /tmp/bzfile >/dev/null 2>&1
        logme "save my current work dir "
        logme "clean /tmp/repack"
        /usr/bin/rm -r /tmp/repack >/dev/null 2>&1
        logme "create a repack dir"
        mkdir /tmp/repack >/dev/null 2>&1
        logme "Jump in to zip repack dir"
        cd /tmp/repack
        bunzip2  /tmp/bzfile.bz2  >/dev/null 2>&1
	cp /tmp/bzfile ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.tar >/dev/null 2>&1
	gzip -f ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.tar >/dev/null 2>&1
        logme "Uploading repacked tar"
        scp ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.${EXTENTION}   root@repos.pip2scl.dk:/usr/share/nginx/html/SOURCES/${OURNAME} >/dev/null 2>&1
        logme "clean /tmp/repack"
        OURURL="http://repos.pip2scl.dk/SOURCES/${OURNAME}"
        redis-cli set $MYURL "$OURURL"  >/dev/null 2>&1
        redis-cli set $MYEXT "$EXTENTION"  >/dev/null 2>&1
        logme "$PACKAGE Package converted to tgz"
        /usr/bin/rm -r /tmp/repack >/dev/null 2>&1

}



















touchthem ()
{
	/usr/bin/rm -rf /tmp/touchthem >/dev/null 2>&1
	mkdir /tmp/touchthem
	cd /tmp/touchthem
	FILE=$1
	FILETYPE=`file $1`
	if [[ $? == 0 ]];
	then
		logme "The file $FILE is $FILETYPE"
		echo tar xzf $FILE
		tar xzf $FILE
		MYDIRINTAR=`ls -1`
		logme "DIR in tar is $MYDIRINTAR"
		MYVERINTAR=`echo $MYDIRINTAR |rev |awk -F'-' '{ print $1 }'|rev`
		MYNAMEINTAR=`echo $MYDIRINTAR |awk -F"-$MYVERINTAR" '{ print $1 }'`
		logme "Name in tar is $MYNAMEINTAR"
		logme "Version in tar is $MYVERINTAR"
		MYDIR="${NAME}-${VERSION}"
		if   [[ $MYDIRINTAR != $MYDIR ]];
		then
			mv $MYDIRINTAR $MYDIR
		fi	
		touch ${MYDIR}/README.md
        	touch ${MYDIR}/CHANGELOG.rst
		tar czf $FILE  $MYDIR >/dev/null 2>&1
		scp $FILE root@repos.pip2scl.dk:/usr/share/nginx/html/SOURCES/ >/dev/null 2>&1
	else
		logme "Something weird happened"
		exit
	fi

}


repack ()
{
	
	logme "Repack"
	VERTOBE=`echo $1 |rev |awk -F'-' '{ print $1 }' |rev`
	NAMETOBE=`echo $1 |awk -F"-$VERTOBE"  '{ print $1 }'`

	VERWAS=`echo $2 |rev |awk -F'-' '{ print $1 }' |rev`
	NAMEWAS=`echo $2 |awk -F"-$VERWAS"  '{ print $1 }'`
	logme "$NAMEWAS must be $NAMETOBE"
	sed -i "s/%define name ${NAMEWAS}/%define name ${NAMETOBE}/" $SPEC
	sed -i "s/%define version ${VERWAS}/%define version ${VERTOBE}/" $SPEC
}
	

download_source ()
{
	NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
	VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
	MYKEY="filename:${PACKAGE}"
	MYCRC="crc:$PACKAGE"
	DOWNFILE=`redis-cli get $MYKEY 2>&1`
	MYURL="url:${PACKAGE}"
	MYEXT="ext:${PACKAGE}"
	MYSRCURL="srcurl:${PACKAGE}"
	
	URL=`redis-cli get $MYURL`
	logme "Our url is $URL"
	if [[ $URL == ""  ]];
	then
		logme "This is a new file - Download" 
        	echo $PACKAGE > /tmp/requirements.txt
        	cd /tmp && DOWNLOAD=`python3 /usr/local/bin/pip-downloader.py `
        	FILEPATH=`echo $DOWNLOAD | awk -F"Downloading:" '{ print $2 }' |awk '{ print $1 }' `
		echo $FILEPATH  |grep -i http >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "File has an URL  $FILEPATH"
			redis-cli set $MYSRCURL $FILEPATH >/dev/null 2>&1
			if [[ $? == 0 ]];
			then
				logme "Filepath saved in redis"
			else
				logme "Redis save failed"
				exit
			fi
		else
			logme "File is unknown"
			exit
		fi
		FILENAME=`echo $FILEPATH |rev |awk -F'/' '{ print $1 }'|rev`
		LAST=`echo $FILENAME |rev | awk -F'-' '{ print $1 }'|rev`
		FIRST=`echo $FILENAME |awk -F"-${LAST}" '{ print $1 }'`
		if [[ $FIRST == $NAME ]];
		then
			logme "name  $FIRST is $NAME is correct in downloaded file"
		else
			logme "name $FIRST is not $NAME and is wrong in downloaded file"
			REALNAME="${NAME}-${LAST}"
			cp -f $BUILDDIR/DOWNLOADS/$FILENAME $BUILDDIR/DOWNLOADS/$REALNAME
			if [[ $? == 0 ]];
			then
				logme "$FILENAME is copied to $REALNAME"
			else
				logme "$FILENAME is copied to $REALNAME"
			fi
		fi
		FILENAME="${NAME}-${LAST}"
		redis-cli set $MYSRCNAME $FILENAME >/dev/null 2>&1

		logme "Filename $FILENAME stored in redis"

		EXTENTION=`echo $FILENAME | rev |awk -F'.' '{ print $1}'|rev `
		logme "File extention is $EXTENTION"
		KNOWNEXT="no"
		OURNAME="${NAME}-${VERSION}.${EXTENTION}"
		logme "$FILENAME downloaded"

	 	if [[ $EXTENTION == "gz" ]];
                then
			KNOWNEXT="yes"
			####################
			#Her should the check for name i tar be moved
			SUM=`sum $BUILDDIR/DOWNLOADS/$FILENAME `
			if [[ $? == 0 ]];
			then
				logme "SUM: $SUM"
				redis-cli set $MYSUM $SUM >/dev/null 2>&1
			else
				logme "noSUM: Unexpected error "
				exit
			fi
			cp $BUILDDIR/DOWNLOADS/$FILENAME $BUILDDIR/SOURCES/$FILENAME
			if [[ $? == 0 ]];
			then
				logme "file placed in SOURCES"
			else
				logme "File not copied to sources"
				exit
			fi
                fi

		if [[ $EXTENTION == "zip" ]];
		then
			KNOWNEXT="yes"
			FILENAME=`echo $FILENAME |sed 's/zip/tar.gz/'`
			#repack to tar gz
			logme "Repack to tar gz"
			zip2tgz 
			ls -l  $BUILDDIR/SOURCES/$FILENAME >/dev/null 2>&1
			if [[ $? == 0 ]];
			then
				logme "We have a tgz version of the file"
			else
				logme "We dont have a tgz version of the file"
				exit
			fi
		fi

		if [[ $EXTENTION == "bz2" ]];
		then
			KNOWNEXT="yes"
                        OURURL="http://repos.pip2scl.dk/SOURCES/${OURNAME}"
                        redis-cli set $MYURL "$OURURL"  >/dev/null 2>&1
                        redis-cli set $MYEXT "$EXTENTION"  >/dev/null 2>&1
                        URL=`redis-cli get $MYURL`
			bz2tgz
		fi
		EXTENTION="tar.gz"

		SRCURL=`echo $DOWNLOAD | awk -F"URL:" '{ print $2 }'`
		redis-cli set $MYSRCURL "$SRCURL"  >/dev/null 2>&1
		touchthem $BUILDDIR/SOURCES/${NAME}-${VERSION}.tar.gz 
		scp $BUILDDIR/SOURCES/${NAME}-${VERSION}.tar.gz root@repos.pip2scl.dk:/usr/share/nginx/html/SOURCES/${NAME}-${VERSION}.tar.gz >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "Package downloaded"
		else
			logme "Package download failed"
			exit
		fi
	else
		logme "$PACKAGE Already Downloaded"
	fi

	EXTENTION=`redis-cli get $MYEXT 2>&1`

	logme "tar file refreshed"
		
}


build_wheels ()
{
	python3 setup.py bdist_wheel >/tmp/buildwheels.log 2>&1
}


checkpackage ()
{
        NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
        VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
        MYKEY="filename:${PACKAGE}"
        MYURL="url:${PACKAGE}"
        MYCRC="crc:$PACKAGE"
	MYDIRKEY="pkgdir:${PACKAGE}"
	EXTENTION="tar.gz"
	SPECFILECREATE="no"
	TARFILE="${BUILDDIR}/SOURCES/${NAME}-${VERSION}.${EXTENTION}"
	if [[ -f $TARFILE ]];
	then
		logme "$TARFILE is here"
	else
		redis-cli get $MYURL
	fi


	/usr/bin/rm -r /tmp/sandbox >/dev/null 2>&1 || logme "cleaner"
	mkdir /tmp/sandbox
	cd /tmp/sandbox
	logme "Is file a gz file"
	if [[ $EXTENTION == "tar.gz" ]];
	then
		logme "Extract the source from $FILE"
		tar xf $TARFILE
		if [[ $? == 0 ]];
		then
			logme "Source extrated"
			NIT=`ls -1`
			redis-cli set $MYNIT $NIT >/dev/null 2>&1
		else
			logme "Extration failed"
			exit 22
		fi
	fi
	
	logme "name in tar $NIT"
	logme "Check $NIT"
	MYDIRKEY="pkgdir:${PACKAGE}"
	redis-cli set $MYDIRKEY "${NIT}" >/dev/null 2>&1
 	cd $NIT
	if [[ $? == 0 ]];
	then
		logme "Entered tar dir $NIT"
	else
		logme "Error changing to dest $NIT" 
		exit
	fi

	logme "Pretty"
	touch README.md
	touch CHANGELOG.rst


	##########################################################
	# check if a handcrafted hardcoded spec file exists
	###########################################################

	#curl "http://repos.pip2scl.dk/SPECS/${NAME}-${VERSION}.hardcoded.spec" >/tmp/hardcoded.spec
	#if [[ $? == 0 ]];
	#then
#		logme "Spec file is hardcoded"
#		mkdir dist >/dev/null 2>&1
#		curl "http://repos.pip2scl.dk/SPECS/${NAME}-${VERSION}.hardcoded.spec" >dist/${NAME}-${VERSION}.spec
#		SPECFILECREATE="HARD"
#	fi


        if [[ $SPECFILECREATE == "no" ]];
        then
                python3 setup.py bdist_rpm --spec-only >/dev/null 2>&1
                if [[ $? == 0 ]];
                then
			logme "Spec file is working on python 3"
                        PYCMD="python3"
                        SPECFILECREATE="yes"
                fi
        fi

	
	if [[ $SPECFILECREATE != "HARD" ]];
	then
		python3.8 setup.py bdist_rpm --spec-only >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "Spec file is working on python 3.8"
			PYCMD="python3.8"
			SPECFILECREATE="yes"
		fi
	fi

	if [[ $SPECFILECREATE == "no" ]];
	then
		python2 setup.py bdist_rpm --spec-only >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "Spec file is working on python 2"
			PYCMD="python2"
			SPECFILECREATE="yes"
		fi
	fi

	if [ $SPECFILECREATE == "yes" ];
	then
		$PYCMD setup.py bdist_rpm --spec-only >/tmp/specfile.$PACKAGE.log 2>&1
		if [[ $? == 0 ]]
		then
			logme "spec file created"
		else
			echo "error: $PACKAGE - spec creation failed"
			cat /tmp/specfile.$package.log
			exit
		fi
	else
		if [ $SPECFILECREATE == "HARD" ];
		then
			logme "Spec file is hardcoded"
		else
			logme "Spec file creation failed"
			exit
		fi
	fi

		
	cd dist
	SPEC=`ls -1`
	
	sed -i "s/^python /$PYCMD /" $SPEC
	sed -i "s/^%{__python} /$PYCMD /" $SPEC
	

	NAMEINSPEC=`grep "define name " $SPEC |awk '{ print $2 }' `
	SPECDST="/root/rpmbuild/SPECS/${NAME}-${VERSION}.spec"
	logme "SPEC $SPEC created and saving it"
	###################

	cat $AUTOPATCH >/dev/null 2>&1
	if [[ $? == 0 ]];
	then
		logme "Autopatch specfile $PACKAGE"
		bash $AUTOPATCH $SPEC >/dev/null 2>&1
	fi

	cp $SPEC $SPECDST
	if [[ $? == 0 ]];
	then
        	redis-cli set  $MYSPEC  $SPECDST >/dev/null 2>&1
	else
		logme "copy failed"
		exit
	fi
	/usr/bin/rm -r /tmp/sandbox /dev/null 2>&1
}

build_rpm ()
{
	logme "We are ready to build"
        NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
        VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
        MYKEY="filename:${PACKAGE}"
        MYURL="url:${PACKAGE}"
        MYCRC="crc:$PACKAGE"
        MYDIRKEY="pkgdir:${PACKAGE}"
	MYSPEC="specfile:${PACKAGE}"
	SPEC=`redis-cli get $MYSPEC`
	logme "My spec file is : $SPEC"
	if [[ -f $SPEC ]];
	then
		logme "File $SPEC is found"
	else
		logme "File $SPEC not  found"
		exit
	fi

	NAMEINSPEC=`grep "define name" $SPEC |awk '{ print $3 }'`
	EXTENTION="tar.gz"
	TARFILE="${BUILDDIR}/SOURCES/${NAME}-${VERSION}.${EXTENTION}"
	URL=`redis-cli get  $MYURL`
	logme "We want to build $BUILDDIR/VERSPEC/${NAME}-${VERSION}.verified.spec"
	logme "We are ready to pretty spec"
	sed -i "s/define version 0.0.0/define version ${VERSION}/" $SPEC
	sed -i "s/define unmangled_version 0.0.0/define unmangled_version ${VERSION}/" $SPEC
 	sed -i 's(%{__python}(/usr/bin/python3(' $SPEC	
	sed -i "s(Source0: .*(Source0: http://repos.pip2scl.dk/SOURCES/${NAME}-${VERSION}.${EXTENTION}(" $SPEC



	if [[ $PACKAGE == "pyOpenSSL==19.1.0" ]];
	then
		logme "Hack we need bleeeding edge"
		echo "python3 -m pip install --upgrade pip" > $SPEC.add
		echo "python3 -m pip install --upgrade setuptools_rust" >> $SPEC.add
		echo "python3 -m pip install --upgrade wheel"  >> $SPEC.add
		/usr/local/bin/mergefiles.sh ${SPEC}   $SPEC.add "%build"     >/dev/null 2>&1
		/usr/local/bin/mergefiles.sh ${SPEC}   $SPEC.add "%install"   >/dev/null 2>&1
	fi



	if [[ $PACKAGE == "pyOpenSSL==19.1.0" ]];
	then
		sed -i "s(BuildRequires:.*(BuildRequires: openssl-devel python3-devel python3-sphinx(" $SPEC
	fi



        if [[ $PACKAGE == "Django==2.2.16" ]];
        then
		logme "Do some django patch"
#		sed -i "s(# Sort the filelist so that directories appear before files. This avoids(sed -i 's)#!/usr/bin/env python*.)#!/usr/bin/env python3)'  \${RPM_BUILD_ROOT}/usr/lib/python3.8/site-packages/django/conf/project_template/manage.py-tpl(" $SPEC
#		sed -i "s(# duplicate filename problems on some systems.(sed -i 's)#!/usr/bin/env python*.)#!/usr/bin/env python3)'  \${RPM_BUILD_ROOT}/usr/lib/python3.8/site-packages/django/bin/django-admin.py(" $SPEC

	fi

        ##########################################################################################################################################################
        if [[ $PACKAGE == "importlib-metadata==4.8.1" ]]
        then
		logme "Force pyton 3.8"
		sed -i "s/python3 /python3.8 /" $SPEC
        fi

        ##########################################################################################################################################################
        if [[ $PACKAGE == "importlib-resources==5.2.2" ]]
        then
		logme "Force pyton 3.8"
		sed -i "s/python3 /python3.8 /" $SPEC
        fi





	##########################################################################################################################################################
	if [[ $PACKAGE == "ruamel.yaml==0.16.10" ]]
	then
		logme "Hack. add files"
		echo 'mkdir -p ${RPM_BUILD_ROOT}/usr/lib/python3.8/site-packages/ruamel/yaml' > /tmp/ruamel.yaml.add
		echo 'touch ${RPM_BUILD_ROOT}/usr/lib/python3.8/site-packages/ruamel/yaml/LICENSE' >> /tmp/ruamel.yaml.add
		/usr/local/bin/mergefiles.sh ${SPEC}   /tmp/ruamel.yaml.add "%clean"  before    >/dev/null 2>&1
	fi


	##########################################################################################################################################################
	if [[ $PACKAGE == "netaddr==0.7.19" ]]
	then	
		logme "TEST"
		/usr/local/bin/mergefiles.sh ${SPEC}  ${PRETTYSPEC}.netaddr "%install"    >/dev/null 2>&1
		
	fi
	


	logme "PrettySPEC = $PRETTYSPEC"	
	####################  Run Pretty spec ####################################################################################################################
	/usr/local/bin/mergefiles.sh ${SPEC}  ${PRETTYSPEC} "%clean" before   >/dev/null 2>&1
	logme "Spec pretty"


	############## Run a plain Standart Python 3 build #######################################################################################################
        ##########################################################################################################################################################
	ALTBUILD="no"
	BUILD="no"
	logme "rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC "
	rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
	cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
	if [[ $? == 0 ]];
	then
		logme "RPMs build"
		redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
		for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
		do	
			MYRPM="rpm:${PACKAGE}"
			MYSRPM="rpms:${PACKAGE}"
			SRPM=`echo $RPM |grep "/SRPMS/"`
			RPM=`echo $RPM |grep "/RPMS/"`
			redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
			redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
			BUILD="ok"
		done
	else
        ##########################################################################################################################################################
		logme "RPMS Failed to build with std python setup "		
		# Sometimes python3.8 is needed
		cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep "find_namespace:" >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			ALTBUILD="python3.8"
			sed -i "s(python3 setup.py (python3.8 setup.py  (" $SPEC
			rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
			cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
			if [[ $? == 0 ]];
			then
				logme "RPMs build with python 3.8"
                		redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
                		for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
                		do
                        		MYRPM="rpm:${PACKAGE}"
                        		MYSRPM="rpms:${PACKAGE}"
                        		SRPM=`echo $RPM |grep "/SRPMS/"`
                        		RPM=`echo $RPM |grep "/RPMS/"`
                        		redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
                        		redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
					BUILD="ok"
				done
			fi
		fi



		#sometimes they just 'forgot some files
        ##########################################################################################################################################################
		cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep "Installed (but unpackaged) file(s) found:" >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			ALTBUILD="ADD files"
               		logme "add some files to the spec file"
			grep " Installed (but unpackaged) file(s) found:" -A100000  $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log  |grep  "RPM build errors:" -B100000 |  sed -e 's/^[ \t]*//' |  grep '^/' | sed 's/^/"/' |sed 's/$/"/' >> $SPEC
		        rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
        		cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:"
        		cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
        		if [[ $? == 0 ]];
        		then
               			logme "RPMs build and some files added"
				BUILD="ok"
                		redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
                		for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
                		do
                        		MYRPM="rpm:${PACKAGE}"
                        		MYSRPM="rpms:${PACKAGE}"
                        		SRPM=`echo $RPM |grep "/SRPMS/"`
                        		RPM=`echo $RPM |grep "/RPMS/"`
                        		redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
                        		redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
					BUILD="ok"
                		done
			fi
		fi

                #sometimes they just 'forgot  the shebang must be forced 
        ##########################################################################################################################################################
                cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep '*** ERROR: ./' | grep 'has shebang which doesn'  >/dev/null 2>&1
                if [[ $? == 0 ]];
                then
                        ALTBUILD="Shebang error"
                	cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep '*** ERROR: ./' | grep 'has shebang which doesn'    \
                        |awk -F'ERROR: ' '{ print $2 }' |awk -F' has shebang which doesn' '{ print $1 }' | sed 's(^./(\${RPM_BUILD_ROOT}/('  |xargs -i{}  echo "sed -i \"1,1s(.*(#!/usr/bin/env python3(\" {} " > SHEBANGFILES
                	/usr/local/bin/mergefiles.sh ${SPEC} SHEBANGFILES  "%clean" before 
                        logme "Clean some scripts"
                        rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
                        cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:"
                        cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
                        if [[ $? == 0 ]];
                        then
                                logme "RPMs build and some files added"
                                BUILD="ok"
                                redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
                                for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
                                do
                                        MYRPM="rpm:${PACKAGE}"
                                        MYSRPM="rpms:${PACKAGE}"
                                        SRPM=`echo $RPM |grep "/SRPMS/"`
                                        RPM=`echo $RPM |grep "/RPMS/"`
                                        redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
                                        redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
                                        BUILD="ok"
                                done
                        fi
                fi

        ##########################################################################################################################################################
		cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep   "No such file or directory"  >/dev/null 2>&1
		if [[ $? == 0  ]];
		then
			logme "No such file or directory"
			if [[ $EXTENTION == "tar.gz" ]];
			then
				NAMEINBUILD=`cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep   "No such file or directory" |awk -F'cd:' '{ print $2 }' |awk '{ print $1 }'  |awk -F':' '{ print $1 }'| grep -i [a-z] ` 
				if [[ $NAMEINBUILD != "" ]]
				then
					logme "name in build: $NAMEINBUILD"
					NAMEINTAR=`tar tvf ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.${EXTENTION} |head -1 | awk -F':' '{ print $2 }' |cut -c 4- |awk -F'/' '{ print $1 }' `
					logme "name in tar: $NAMEINTAR"
					if [[ $NAMEINBUILD != $NAMEINTAR ]];
					then
						logme "name in builds differs from tar . Repack $NAMEINTAR : $NAMEINBUILD"
						repack $NAMEINTAR $NAMEINBUILD
						rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
		                	        cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
                        			if [[ $? == 0 ]];
                        			then
                                			logme "RPMs build and some files added"
                                			BUILD="ok"
                                			redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
                                			for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
                                			do
                                        			MYRPM="rpm:${PACKAGE}"
                                        			MYSRPM="rpms:${PACKAGE}"
                                       		 		SRPM=`echo $RPM |grep "/SRPMS/"`
                                        			RPM=`echo $RPM |grep "/RPMS/"`
                                        			redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
                                        			redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
                                        			BUILD="ok"
                                			done
                        			fi
					fi
				fi
			fi
		fi
        ##########################################################################################################################################################

        ##########################################################################################################################################################
		cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep   "Arch dependent binaries in noarch package"  >/dev/null 2>&1
		if [[ $? == 0  ]];
		then
			logme "Arch dependent binaries in noarch package"
			sed -i "s/BuildArch: noarch/BuildArch: x86_64/" ${SPEC} 
			cat $SPEC|grep -i buildarch
			echo $SPEC
			rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  
			rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
                        cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
                        if [[ $? == 0 ]];
                        then
                        	logme "RPMs build and some files added"
                                BUILD="ok"
                                redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
                                for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
                                do
                                        MYRPM="rpm:${PACKAGE}"
                                        MYSRPM="rpms:${PACKAGE}"
                                        SRPM=`echo $RPM |grep "/SRPMS/"`
                                        RPM=`echo $RPM |grep "/RPMS/"`
                                        redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
                                        redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
                                        BUILD="ok"
                                done
                         fi
		fi


        ##########################################################################################################################################################

        ##########################################################################################################################################################
                cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep   "ambiguous python shebang in"  >/dev/null 2>&1
                if [[ $? == 0  ]];
                then
                        logme "No such file or directory"
                        if [[ $EXTENTION == "gz" ]];
                        then
                                find  . -type f |grep "\.py" |xargs -i{} sed -i "1,1s(#!/usr/bin/env python.*(#!/usr/bin/env python3(" {}  > /tmp/AUTOPATCH
                                /usr/local/bin/mergefiles.sh ${SPEC}  /tmp/AUTOPATCH "%install"
                                rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
                                cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
                                if [[ $? == 0 ]];
                                then
                                     logme "RPMs build and some files added"
                                     BUILD="ok"
                                     redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
                                     for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
                                     do
                                          MYRPM="rpm:${PACKAGE}"
                                          MYSRPM="rpms:${PACKAGE}"
                                          SRPM=`echo $RPM |grep "/SRPMS/"`
                                          RPM=`echo $RPM |grep "/RPMS/"`
                                          redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
                                          redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
                                          BUILD="ok"
                                     done
                                fi
                        fi
                fi


        ##########################################################################################################################################################


        ##########################################################################################################################################################
                cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log | grep   "FileNotFoundError:"  >/dev/null 2>&1
                if [[ $? == 0  ]];
                then
                        logme "FileNotFoundError:"
                        if [[ $EXTENTION == "gz" ]];
                        then
				NAMEINTAR=`tar tvf ${BUILDDIR}/SOURCES/${NAME}-${VERSION}.${EXTENTION} |head -1 | awk -F':' '{ print $2 }' |cut -c 4- |awk -F'/' '{ print $1 }' `
				repack  $NAMEINTAR $NAMEINTAR
                                rpmbuild -ba -D 'debug_package %{nil}' --clean  $SPEC  >$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log 2>&1
                                cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" >/dev/null 2>&1
                                if [[ $? == 0 ]];
                                then
                                     logme "RPMs build and some files added"
                                     BUILD="ok"
                                     redis-cli set $MYRPMSPEC "$SPEC"  >/dev/null 2>&1
                                     for RPM in `cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log |grep "^Wrote:" | awk -F"Wrote: "  '{ print $2 }' `
                                     do
                                          MYRPM="rpm:${PACKAGE}"
                                          MYSRPM="rpms:${PACKAGE}"
                                          SRPM=`echo $RPM |grep "/SRPMS/"`
                                          RPM=`echo $RPM |grep "/RPMS/"`
                                          redis-cli set $MYRPM "$RPM"  >/dev/null 2>&1
                                          redis-cli set $MYSRPM "$SRPM"    >/dev/null 2>&1
                                          BUILD="ok"
                                     done
                                fi



                        fi
                fi


        ##########################################################################################################################################################


		cat $BUILDOUT/${NAME}-${VERSION}.rpmbuild.log    |grep "error: Bad source: "
		if [[ $? == 0  ]];
		then
			logme "Bad Source"
			exit
		fi
	fi





	if [[ $BUILD == "ok" ]];
	then
		logme "RPMS build with std : remarks $ALTBUILD "		
		MYVERIFIEDSPEC="SPEC_VERIFY:${PACKAGE}"
		scp $SPEC root@repos.pip2scl.dk:/usr/share/nginx/html/SPECS/${NAME}-${VERSION}.verified.spec
	else
		logme "RPMS build failed	"
		redis-cli set $MYERR "$BUILDOUT/${NAME}-${VERSION}.rpmbuild.log" >/dev/null 2>&1  
	fi
}	
	
	
build_scl ()
{
	logme "adding $PACKAGE to software collection $SCL"
	MYSPEC="specfile:${PACKAGE}"
	MYSCLSRPM="sclsrpm:${PACKAGE}"
	MYSCLRPM="sclrpm:${PACKAGE}"
	VERSPECURL=`redis-cli get $MYVERSPEC`
	mkdir $BUILDDIR/VERSPEC >/dev/null 2>&1
	mkdir $BUILDDIR/PRESPEC >/dev/null 2>&1
	mkdir $BUILDDIR/SCLSPEC >/dev/null 2>&1
	URL=`redis-cli get $MYURL `
	
	NAMEINTAR=`tar tvf $BUILDDIR/SOURCES/${NAME}-${VERSION}.tar.gz |head -1 |awk '{ print $6 }' |sed 's(/(('`
	wget -O $BUILDDIR/VERSPEC/${NAME}-${VERSION}.verified.spec   $VERSPECURL >/dev/null 2>&1
	logme "Our verified SPEC is $BUILDDIR/VERSPEC/${NAME}-${VERSION}.verified.spec"


        ##########################################################
        # check if a handcrafted hardcoded spec file exists
        ###########################################################

        logme "curl \"http://repos.pip2scl.dk/SPECS/${NAME}-${VERSION}.hardcoded.scl.spec\""
	CURL=`curl "http://repos.pip2scl.dk/SPECS/${NAME}-${VERSION}.hardcoded.scl.spec" 2>/dev/null|grep "The page you are looking for is not found"`
        if [[ $? != 0 ]];
        then
               	logme "scl Spec file is hardcoded"
		SCLFILEPRE="$BUILDDIR/PRESPEC/${NAME}-${VERSION}.scl.spec.pre"
		SCLFILE="$BUILDDIR/PRESPEC/${NAME}-${VERSION}.scl.spec"
               	CURL=`curl "http://repos.pip2scl.dk/SPECS/${NAME}-${VERSION}.hardcoded.scl.spec" >$BUILDDIR/PRESPEC/${NAME}-${VERSION}.scl.spec.pre 2>/dev/null`
               	SPECFILECREATE="HARD"
	else
		logme "Create spec file"
		spec2scl  $BUILDDIR/VERSPEC/${NAME}-${VERSION}.verified.spec > $BUILDDIR/PRESPEC/${NAME}-${VERSION}.scl.spec.pre  2>/dev/null
		logme "Our SCL specfile before mod is $BUILDDIR/PRESPEC/${NAME}-${VERSION}.scl.spec.pre"
		SCLFILEPRE="$BUILDDIR/PRESPEC/${NAME}-${VERSION}.scl.spec.pre"
		SCLFILE="$BUILDDIR/PRESPEC/${NAME}-${VERSION}.scl.spec"
		logme "Check if the spec file has been prettified"
		AFTERLINE=`cat $SCLFILEPRE | grep "python3 setup.py install" -A1 | tail -1`
		echo "$AFTERLINE"  |grep '%{?scl:EOF}' >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "We need to append this line in the the scl spec file after python setup and before scl"
			grep "python3 setup.py install" -B1000000 $SCLFILEPRE >/tmp/header
			grep "python3 setup.py install" -A1000000 $SCLFILEPRE | grep -v "python3 setup.py install" >/tmp/footer
		fi
        	sed -i 's#root=$RPM_BUILD_ROOT#root=$RPM_BUILD_ROOT/opt/miracle/miracle-awx/root#'  $SCLFILEPRE
        	sed -i "s#%setup.*#%setup -n ${NAMEINTAR}#" $SCLFILEPRE
        	sed -i "s(#SCLRENAME(sed -i 's#/#/opt/miracle/miracle-awx/root/#' INSTALLED_FILES (" $SCLFILEPRE

	##################################
	#
	####################################
        	if [[ $PACKAGE == "pyOpenSSL==19.1.0" ]];
       		then
			logme "hack require"
			sed -i "s/BuildRequires: %{?scl_prefix}openssl-devel %{?scl_prefix}python3-devel %{?scl_prefix}python3-sphinx/BuildRequires: openssl-devel python3-devel python3-sphinx/" $SCLFILEPRE
		
		fi

	##################################
	#
	####################################
        	if [[ $PACKAGE == "xmlsec==1.3.3" ]];
        	then
			logme "hack require"
			sed -i "s/BuildRequires: %{?scl_prefix}pkg-config %{?scl_prefix}xmlsec1-devel %{?scl_prefix}libxml2-devel %{?scl_prefix}xmlsec1-openssl-devel/BuildRequires: pkg-config xmlsec1-devel libxml2-devel xmlsec1-openssl-devel/" $SCLFILEPRE
		
		fi	




	##################################
	#
	####################################
        	if [[ $PACKAGE == "Django==2.2.16" ]];
        	then
			logme "DJango hack"
        # Sort the filelist so that directories appear before files. This avoids
        # Make sure we match foo.pyo and foo.pyc along with foo.py (but only once each)

                	grep -P "Sort the filelist so that directories appear before files. This avoids" $SCLFILEPRE -B100000 |grep -v "Sort the filelist so that directories appear before files. This avoids" > PART1
                	echo 'sed -i "s(//(/(" INSTALLED_FILES' >> PART1
                	grep -P "^EOF$" $SCLFILEPRE -A100000 |grep -v "^EOF$" > PART2

                	cat PART1 PART2 |grep -v " DIRS FILES" |grep -v /usr/share/man/man1/django-admin.1.gz  |grep  -v '%doc' > $SCLFILEPRE
        	fi

        ##################################
        #
        ####################################
        	if [[ $PACKAGE == "uWSGI==2.0.18" ]];
        	then
	  		sed -i 's#"/usr/bin/uwsgi"##' $SCLFILEPRE
	  		echo "/opt/miracle/miracle-awx/root/usr/bin/uwsgi" >> $SCLFILEPRE
          		echo "/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin/uwsgi-2.0.18-1.x86_64.debug" >> $SCLFILEPRE
        	fi

        ##################################
        #
        ####################################
        	if [[ $PACKAGE == "ruamel.yaml.clib==0.2.0" ]];
        	then
	  		sed -i 's#"/usr/bin/uwsgi"##' $SCLFILEPRE
	  		echo "/opt/miracle/miracle-awx/root/usr/bin/uwsgi" >> $SCLFILEPRE
          		echo "/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin/uwsgi-2.0.18-1.x86_64.debug" >> $SCLFILEPRE
        	fi

        ##################################
        #
        ####################################
        	if [[ $PACKAGE == "ruamel.yaml.clib==0.2.0" ]];
		then	
			echo 'mkdir -p /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/opt/miracle/miracle-awx/root/usr/bin' >$SCLFILEPRE.ruamel.yaml.clib-0.2.0.add
			echo 'touch /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/opt/miracle/miracle-awx/root/usr/bin/uwsgi' >> $SCLFILEPRE.ruamel.yaml.clib-0.2.0.add
			echo 'mkdir -p /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin' >>$SCLFILEPRE.ruamel.yaml.clib-0.2.0.add
			echo 'touch /root/rpmbuild/BUILDROOT/miracle-awx-ruamel.yaml.clib-0.2.0-1.x86_64/usr/lib/debug/opt/miracle/miracle-awx/root/usr/bin/uwsgi-2.0.18-1.x86_64.debug' >>$SCLFILEPRE.ruamel.yaml.clib-0.2.0.add
	       	 	/usr/local/bin/mergefiles.sh ${SCLFILEPRE}  ${SCLFILEPRE}.ruamel.yaml.clib-0.2.0.add "%clean" before   >/dev/null 2>&1
		fi



        ##################################
        #
        ####################################
	        if [[ $PACKAGE == "ruamel.yaml==0.16.10" ]];
		then
			echo "/usr/lib/python3.8/site-packages/ruamel/yaml/LICENSE"  >> $SCLFILEPRE
		fi

        ##################################
        #
        ####################################
        	if [[ $PACKAGE == "jaraco.text==3.2.0" ]]
        	then
                	logme "Hack. add files"
      			echo 'mkdir -p "/root/rpmbuild/BUILDROOT/miracle-awx-jaraco.text-3.2.0-1.x86_64/usr/lib/python3.8/site-packages/jaraco/text" ' >  $SCLFILEPRE.add
      			echo 'touch "/root/rpmbuild/BUILDROOT/miracle-awx-jaraco.text-3.2.0-1.x86_64/usr/lib/python3.8/site-packages/jaraco/text/Lorem ipsum.txt" ' >>  $SCLFILEPRE.add
       	 		/usr/local/bin/mergefiles.sh ${SCLFILEPRE}  ${SCLFILEPRE}.add "%clean" before   >/dev/null 2>&1
                	echo '"/opt/miracle/miracle-awx/root/usr/lib/python3.8/site-packages/jaraco/text/Lorem ipsum.txt"' >> $SCLFILEPRE
        	fi
	fi

	logme "rpmbuild -ba -D 'debug_package %{nil}' --clean $SCLFILEPRE --define \"scl miracle-awx\" "
	rpmbuild -ba -D 'debug_package %{nil}' --clean $SCLFILEPRE --define "scl miracle-awx" >/tmp/prebuild.log 2>&1
	grep "Wrote:" /tmp/prebuild.log >/dev/null 2>&1
	if [[ $? == 0 ]];
	then
		logme "scl build succeeded"
		cp $SCLFILEPRE $SCLFILE
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
while [[ $LOOP != 0 ]];
do
	MYRPM="rpm:${PACKAGE}"
	MYSRPM="rpms:${PACKAGE}"
	SPEC=`redis-cli get $MYSPEC 2>&1`
	SPECNAME=`echo $SPEC| rev |awk -F'/' '{ print $1 }' |rev| sed 's/\\.spec/\\.verified\\.spec/'`
        CURL=`curl "http://repos.pip2scl.dk/SPECS/${NAME}-${VERSION}.hardcoded.scl.spec"  2>/dev/null |grep "The page you are looking for is not found" `
        if [[ $? != 0 ]];
        then
                logme "scl Spec file is hardcoded"
		LOOP=0
	else
                logme "scl Spec file is needs to be build"
		VERSPEC=`redis-cli get $MYVERSPEC 2>&1`
		SRPM=`redis-cli get $MYSRPM 2>&1`
		RPM=`redis-cli get $MYRPM 2>&1`
		if [[ $RPM == "" ]];
		then
			logme "Download source "
			download_source
			logme "check source "
			checkpackage
			logme "build the std rpm "
			build_rpm
			LOOP=$((LOOP-1))
		else
			logme "Package already build"
               		scp $SPEC root@repos.pip2scl.dk:/usr/share/nginx/html/SPECS/${NAME}-${VERSION}.verified.spec >/dev/null 2>&1
			VERSPECURL="http://repos.pip2scl.dk/SPECS/${SPECNAME}"
			redis-cli set $MYVERSPEC $VERSPECURL >/dev/null 2>&1 
			logme "My verified specfile is $SPECNAME and located  $VERSPECURL"
			LOOP=0
		fi
		build_scl
	fi
done
