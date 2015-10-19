#!/bin/bash
basedir=`dirname $0`


DEMO="JBoss Fuse and Data Grid Demo"
AUTHORS="Thomas Qvarnstrom, Red Hat & Christina Lin, Red Hat"
SRC_DIR=$basedir/installs

FUSE_INSTALL=jboss-fuse-full-6.2.0.redhat-133.zip
JDG_INSTALL=jboss-datagrid-6.5.0-server.zip

SOFTWARE=($FUSE_INSTALL $JDG_INSTALL)


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



# Check that maven is installed and on the path
mvn -v -q >/dev/null 2>&1 || { echo >&2 "Maven is required but not installed yet... aborting."; exit 1; }

# Verify that necesary files are downloaded
for DONWLOAD in ${SOFTWARE[@]}
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

#If fuse is running stop it
echo "  - stopping any running fuse instances"
echo
jps -lm | grep karaf | grep -v grep | awk '{print $1}' | xargs kill -KILL

#If JDG is running stop it
echo "  - stopping any running datagrid instances"
jps -lm | grep jboss-datagrid | grep -v grep | awk '{print $1}' | xargs kill -KILL

sleep 2

echo


# Create the target directory if it does not already exist.
if [ -x target ]; then
		echo "  - deleting existing target directory..."
		echo
		rm -rf target
fi
echo "  - creating the target directory..."
echo
mkdir target



# Unzip the maven repo files
echo "  - installing fuse"
echo
unzip -q -d target $SRC_DIR/$FUSE_INSTALL
if [ "$(uname)" =  "Linux" ]
then
	sed -i "s/#admin/admin/" target/jboss-fuse-6.*/etc/users.properties
else
	sed -i '' "s/#admin/admin/" target/jboss-fuse-6.*/etc/users.properties
fi

echo "  - installing datagrid"
echo
unzip -q -d target $SRC_DIR/$JDG_INSTALL


# Build the projects
echo "  - building the projects"
echo
pushd projects > /dev/null
mvn -q clean install
popd > /dev/null

echo "  - starting fuse"
echo

pushd target/jboss-fuse*/bin > /dev/null
./start
popd > /dev/null

echo "  - starting datagrid"
echo

pushd target/jboss-datagrid*/bin > /dev/null
./standalone.sh > /dev/null 2>&1 &
popd > /dev/null

sleep 20

echo "  - starting client"
echo

pushd target/jboss-fuse*/bin > /dev/null

FUSE_INSTALL_LOG=../../../install.log

echo "" > ${FUSE_INSTALL_LOG}

sh client -r 2 -d 10 "wait-for-service -t 300000 io.fabric8.api.BootstrapComplete" >> ${FUSE_INSTALL_LOG} 2>&1

sh client -r 2 -d 10 "fabric:create --clean --wait-for-provisioning --profile fabric"  >> ${FUSE_INSTALL_LOG} 2>&1

sh client -r 2 -d 10 "fabric:profile-edit --pid io.fabric8.agent/org.ops4j.pax.url.mvn.repositories='https://maven.repository.redhat.com/ga@id=jboss-ga-repository' default" >> ${FUSE_INSTALL_LOG} 2>&1

sh client -r 2 -d 10 "fabric:profile-edit --repositories mvn:org.apache.camel/camel-jbossdatagrid/6.5.0.Final-redhat-5/xml/features default" >> ${FUSE_INSTALL_LOG} 2>&1

#sh client -r 2 -d 10 "fabric:profile-edit --repositories mvn:org.infinispan/infinispan-remote/6.2.0.Final-redhat-4/xml/features default" > /dev/null 2>&1

sh client -r 2 -d 10 "fabric:profile-edit --repositories mvn:org.jboss.demo.jdg/features/1.0.0/xml/features default" >> ${FUSE_INSTALL_LOG} 2>&1

sh client -r 2 -d 10 "fabric:profile-create --parents feature-camel --version 1.0 demo-local_producer" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-create --parents feature-camel --version 1.0 demo-local_consumer" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-create --parents feature-camel --version 1.0 demo-remote_producer" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-create --parents feature-camel --version 1.0 demo-remote_consumer" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-create --parents feature-camel --version 1.0 demo-claim_check" >> ${FUSE_INSTALL_LOG} 2>&1


sh client -r 2 -d 10 "fabric:version-create --parent 1.0 --default 1.1" >> /dev/null 2>&1

sh client -r 2 -d 10 "fabric:profile-edit --features local-camel-producer demo-local_producer 1.1" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-edit --features local-camel-consumer demo-local_consumer 1.1" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-edit --features remote-camel-producer demo-remote_producer 1.1" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-edit --features remote-camel-consumer demo-remote_consumer 1.1" >> ${FUSE_INSTALL_LOG} 2>&1
sh client -r 2 -d 10 "fabric:profile-edit --features claim-check-demo demo-claim_check 1.1" >> ${FUSE_INSTALL_LOG} 2>&1

sh client -r 2 -d 10 "container-upgrade --all 1.1" >> ${FUSE_INSTALL_LOG} 2>&1

popd > /dev/null
