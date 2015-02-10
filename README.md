Camel JBoss Data Grid Component Demo
=====================================

This collection of demos show how to use the camel-jbossdatagrid component and some suggested EIP where it can be used.


	
	
Setup
---------------
To setup the infrastructure for the demo download the follwoing files to the `installs` directory:

* jboss-fuse-full-6.1.1.redhat-412.zip
* jboss-datagrid-6.4.0-server.zip

After that run the `init.sh` script

		$ sh init.sh
		
Demos
--------
1. **Local producer** 

	A simple demo that stores a key/value pair in JBoss Data Grid. JDG is deployed as clustered library mode
	
		$ target/jboss-fuse-6.1.1.redhat-412/bin/client -r 2 -d 40 'container-create-child --profile demo-local_producer root local_producer'
	
1. **Local consumer** 

	A simple demo that can react to a `CACHE_ENTRY_MODIFIED` event and read the key/value from JBoss Data Grid. JDG is deployed as clustered library mode. 
	
		$ target/jboss-fuse-6.1.1.redhat-412/bin/client -r 2 -d 40 'container-create-child --profile demo-local_consumer root local_consumer'
1. **Simple-remote-producer**

	A simple demo that stores a key/value pair in JBoss Data Grid. JDG is deployed as a standalone process.
	
		$ target/jboss-fuse-6.1.1.redhat-412/bin/client -r 2 -d 40 'container-create-child --profile demo-remote_producer root remote_producer'
1. **Simple-remote-consumer**

	A simple demo that uses a timer to trigger a get from JBoss Data Grid. JDG is deployed as a standalone process.
	
		$ target/jboss-fuse-6.1.1.redhat-412/bin/client -r 2 -d 40 'container-create-child --profile demo-remote_consumer root remote_consumer'
		
1. **Claim-check-eip** _In progress_
	
	This demos is triggered by a file drop. The content of the file is stored in JDG using remote server (via HotRod). The Camel message is then passed on to a new pipeline. The new pipeline read the content from JDG and writes it to a new output file. 
1. **BI Processing - telco event** _In progress_

	In this demo Fuse/Camel is used to process a dropped CSV file, transform it to Java Object (one per line) which is put into a remote jbossdatagrid. We then start JDG library instances using the remote datagrid as a loader and run map/reduce on the Java Objects to create BI reports. 

	
