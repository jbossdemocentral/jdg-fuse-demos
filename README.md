Camel JBoss Data Grid Component Demo
=====================================

This collection of demos show how to use the camel-jbossdatagrid component and some suggested EIP where it can be used.

Demos
--------
1. **Simple-local-producer** 

	A simple demo that stores a key/value pair in JBoss Data Grid. JDG is deployed as clustered library mode
1. **Simple-local-consumer** 

	A simple demo that can react to a CACHE_ENTRY_MODIFIED event and read the key/value from JBoss Data Grid. JDG is deployed as clustered library mode. 
1. **Simple-remote-producer**

	A simple demo that stores a key/value pair in JBoss Data Grid. JDG is deployed as a standalone process.
1. **Simple-remote-consumer**

	A simple demo that uses a timer to trigger a get from JBoss Data Grid. JDG is deployed as a standalone process.
1. **Claim-check-eip** _In progress_
	
	This demos is triggered by a file drop. The content of the file is stored in JDG using remote server (via HotRod). The Camel message is then passed on to a new pipeline. The new pipeline read the content from JDG and writes it to a new output file. 
1. **BI Processing - telco event** _In progress_

	In this demo Fuse/Camel is used to process a dropped CSV file, transform it to Java Object (one per line) which is put into a remote jbossdatagrid. We then start JDG library instances using the remote datagrid as a loader and run map/reduce on the Java Objects to create BI reports. 
	
	
Setup
---------------
To setup the infrastructure for the demo download the follwoing files to the `installs` directory:

* file1
* file2

After that run the `setup.sh` script

		$ sh setup.sh
		
Run Simple-local-producer Demo
-------------------------------
1. Make sure that you have done the setup.
1. Start a CLI client to Fuse

		$ target/jboss-fuse-6.1.1.redhat-412/bin/client
1. Add the demo config to the root container

		JBossFuse:admin@root> container-add-profile root simple-local-producer-demo

1. Open the log file to verify that everything works

		JBossFuse:admin@root> log:tail
	
