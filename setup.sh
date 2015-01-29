#!/bin/bash
basedir=`dirname $0`


DEMO="JBoss Fuse and Data Grid Demo"
AUTHORS="Thomas Qvarnstrom, Red Hat & Christina Lin, Red Hat"
SRC_DIR=$basedir/installs
MVN_REPO=$basedir/target/local_mvn_repos
REPOS=(jboss-datagrid-6.4.0-maven-repository.zip)

#JDG_SERVER=jboss-datagrid-6.3.0-server.zip
FUSE_INSTALL=jboss-fuse-full-6.1.1.redhat-412.zip


# wipe screen.
clear 

echo

ASCII_WIDTH=52

printf "##  %-${ASCII_WIDTH}s  ##\n" | sed -e 's/ /#/g'
printf "##  %-${ASCII_WIDTH}s  ##\n"   
printf "##  %-${ASCII_WIDTH}s  ##\n" "Setting up the ${DEMO}"
printf "##  %-${ASCII_WIDTH}s  ##\n"
printf "##  %-${ASCII_WIDTH}s  ##\n"
printf "##  %-${ASCII_WIDTH}s  ##\n" "    # ####   ###   ###  ###   ###   ###"
printf "##  %-${ASCII_WIDTH}s  ##\n" "    # #   # #   # #    #      #  # #"
printf "##  %-${ASCII_WIDTH}s  ##\n" "    # ####  #   #  ##   ##    #  # #  ##"
printf "##  %-${ASCII_WIDTH}s  ##\n" "#   # #   # #   #    #    #   #  # #   #"
printf "##  %-${ASCII_WIDTH}s  ##\n" " ###  ####   ###  ###  ###    ###   ###"  
printf "##  %-${ASCII_WIDTH}s  ##\n"
printf "##  %-${ASCII_WIDTH}s  ##\n"
printf "##  %-${ASCII_WIDTH}s  ##\n"   
printf "##  %-${ASCII_WIDTH}s  ##\n" "brought to you by,"
printf "##  %-${ASCII_WIDTH}s  ##\n" "${AUTHORS}"
printf "##  %-${ASCII_WIDTH}s  ##\n"
printf "##  %-${ASCII_WIDTH}s  ##\n"
printf "##  %-${ASCII_WIDTH}s  ##\n" | sed -e 's/ /#/g'

echo
echo "Setting up the ${DEMO} environment..."
echo

# make some checks first before proceeding.	

# Check that maven is installed and on the path

mvn -v -q >/dev/null 2>&1 || { echo >&2 "Maven is required but not installed yet... aborting."; exit 1; }



for DONWLOAD in ${REPOS[@]}
do
	if [[ -r $SRC_DIR/$DONWLOAD || -L $SRC_DIR/$DONWLOAD ]]; then
			echo $DONWLOAD are present...
			echo
	else
			echo You need to download $DONWLOAD from the Customer Support Portal 
			echo and place it in the $SRC_DIR directory to proceed...
			echo
			exit
	fi
done

# Create the target directory if it does not already exist.
if [ ! -x target ]; then
		echo "  - creating the target directory..."
		echo
		mkdir target
else
		echo "  - detected target directory, moving on..."
		echo
fi

# Setting up a local maven repo

# Move the old Maven repo, if it exists, to the OLD position.
if [ -x $MVN_REPO ]; then
		echo "  - detected maven repository, moving on ..."
		echo
else
	# Unzip the maven repo files
	echo "  - unpacking local maven repos"
	echo
	#REPOS=($EAP_MVN_REPO $JDG_MVN_REPO)
	for REPO in ${REPOS[@]}
	do
		unzip -q -d $MVN_REPO $SRC_DIR/$REPO
	done
fi

# Move the old Maven repo, if it exists, to the OLD position.
if [ -x target/jboss-fuse* ]; then
		echo "  - detected Fuse installation, moving on..."
		echo
		#rm -rf $MVN_REPO.OLD
		#mv $MVN_REPO $MVN_REPO.OLD
else
	# Unzip the maven repo files
	echo "  - installing JBoss Fuse"
	echo
	for REPO in ${REPOS[@]}
	do
		unzip -q -d target $SRC_DIR/$FUSE_INSTALL
	done
	sed -i '' "s/#admin/admin/" target/jboss-fuse-6.*/etc/users.properties
fi


# Build the projects
echo "  - buildig the projects"
echo
pushd projects > /dev/null
mvn -q clean install
popd > /dev/null




echo "  - starting fuse"
echo

# Found out the full path to the maven repo
pushd $basedir/$MVN_REPO > /dev/null
	MVN_REPO_FULLPATH=`pwd`
popd > /dev/null

pushd target/jboss-fuse*/bin > /dev/null 

# Make sure that karaf is not running
jps -lm | grep karaf | grep -v grep | awk '{print $1}' | xargs kill -KILL

./start

sleep 20

echo "  - starting client"
echo

echo " DEBUG repo url = ${MVN_REPO_FULLPATH}/jboss-datagrid-6.4.0-maven-repository"

./client << EOF

wait-for-service -t 300000 io.fabric8.api.BootstrapComplete 

fabric:create --clean --wait-for-provisioning --profile fabric

fabric:profile-edit --pid io.fabric8.agent/org.ops4j.pax.url.mvn.repositories='file:${MVN_REPO_FULLPATH}/jboss-datagrid-6.4.0-maven-repository@id=jboss-datagrid-repo' default

fabric:profile-edit --repositories mvn:org.apache.camel/camel-jbossdatagrid/6.4.0.Final-redhat-4/xml/features default

fabric:profile-edit --repositories mvn:org.infinispan/infinispan-remote/6.2.0.Final-redhat-4/xml/features default


fabric:profile-edit --repositories mvn:org.jboss.demo.jdg/features/1.0.0/xml/features default

fabric:profile-create --parents feature-camel --version 1.0 simple-local-producer-demo
fabric:profile-create --parents feature-camel --version 1.0 simple-local-consumer-demo

fabric:version-create --parent 1.0 --default 1.1

fabric:profile-edit --features local-camel-producer simple-local-producer-demo 1.1
fabric:profile-edit --features local-camel-consumer simple-local-consumer-demo 1.1

container-upgrade --all 1.1

#container-add-profile root simple-demo

EOF

