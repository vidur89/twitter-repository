# Twitter Data Ingestion Using Flume

###
# Author: Vidur Nayyar



# Pre-requisites

Before we start we need to make sure that the following has been downloaded on your machine:

1. 1)HDP 2.3.2 sandbox or higher
2. 2) Maven
3. 3)Java exe



## HDP 2.3.2 sandbox or higher

Download the latest HDP sandbox from the Hortonworks website. [http://hortonworks.com](http://hortonworks.com).  You can download the HDP 2.3.2 sandbox from [HDP 2.3.2](http://hortonworks.com/products/hortonworks-sandbox/) . The installation guide can be downloaded from [http://hortonworks.com/wp-content/uploads/2015/07/Import\_on\_Vbox\_7\_20\_2015.pdf](http://hortonworks.com/wp-content/uploads/2015/07/Import_on_Vbox_7_20_2015.pdf) .

Once you have downloaded the HDP sandbox, you can go to the vmbox to open the sandbox as a virtual machine. Please give the sandbox exactly half the amount of RAM memory that your computer has (this RAM allocated for the sandbox should not be less than 3 Gb). When you open the sandbox for the first time, you will need to change the password from Hadoop to a custom password.

You may log in to the sandbox by SSH into it. You will need to use the following script to ssh.

- _ssh root@127.0.0.1 -p 2222_

  Use your local terminal/putty to provide in the new password, because the key might not be recognized in the virtual machine. (It might take a number of attempts to get this right. If you still are not able to login, please download the sandbox again.).

You may also get an error of the RSA key. In that case open the known key file in the .ssh directory . If you are using Mac and had added some other virtual machine on to the [127.0.0.1]2222 ip address you would need to open the .ssh directory by  typing this in the terminal:

- _Open .ssh_

Once then open the known key file and delete the rsa key for the [127.0.0.1]2222 ip address.

**Setting the permissions for the sandbox**

 You would need to set the permissions for the root directory by following the following steps:

- _[hdfs@sandbox root]$ hdfs dfs -mkdir /user/root_
- _[hdfs@sandbox root]$ hdfs dfs -chown root:root /user/root_
- _[hdfs@sandbox root]$ hdfs dfs -chmod -R 777 /user/root_
- _[hdfs@sandbox root]$ hdfs dfs -chmod -R 777 /user/root_

## Maven

Apache Maven is a software project management and comprehension tool. Based on the concept of a project object model (POM), Maven can manage a project's build, reporting and documentation from a central piece of information.

To know more about Maven, you can look for the "About Maven" section of the navigation of [https://maven.apache.org](https://maven.apache.org). This includes an in-depth description of [what Maven is](https://maven.apache.org/what-is-maven.html), a [list of some of its main features](https://maven.apache.org/maven-features.html), and a set of [frequently asked questions about what Maven is](https://maven.apache.org/general.html).

Maven is used to recompile jars that are otherwise corrupted. Maven would download all the imported libraries and link your java code to them. You will need to add the maven code of the libraries to the pop file for maven.

You would need to define your java directory for mavin to work, you can do that by the following script:

- _export JAVA\_HOME=$(/usr/lib/jvm/java-1.7.0-openjdk.x86\_64/jre)_

To download maven you need to do the following:

- _sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo_
- _sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo_
- _sudo yum install -y apache-maven_

To check if maven has been downloaded do the following:

- _mvn –version_

Maven is used to recompile jars that are otherwise corrupted(you don't need to do this, this needs to be done only if the jar file is corrupted. I will make sure that the jar file provided to you is never corrupted. In case it ever is you may recompile using this)

- _put jar file into /usr/hdp/_

## Java exe

Please refer the following link [http://tecadmin.net/steps-to-install-java-on-centos-5-6-or-rhel-5-6/](http://tecadmin.net/steps-to-install-java-on-centos-5-6-or-rhel-5-6/)

# Twitter Flume Source

The updated and working twitter flume source can be found in the git-hub repository [https://github.com/vidur89/twitter-repository.git](https://github.com/vidur89/twitter-repository.git). After opening this link  search for the twitter source jar file, click on raw to download the jar file. This jar file is the twitter flume source jar file.

You can download this folder containing the twitter flume jar file directly into your sandbox, you can do so by running the following command on your sandbox:

- _wget "https://github.com/vidur89/twitter-repository"_

 once downloaded, you would need to move the downloaded jar file into the  /usr/hdp/2.3.2.0-2950/flume/lib  folder in your sandbox. You can do this by running the following command:

- _cp twitter-flume-source-Vidur1.0.jar /usr/hdp/2.3.2.0-2950/flume/lib_



# Twitter Flume Configuration file

Before starting with the flume configuration file, I would advice you to create a folder in your sandbox to place the configuration file and all the files linked to twitter ingestion files.

You can do so by:

- _mkdir TwitterData_

Its beneficial to move the downloaded repository file to this directory:

- _mv twitter-repository/twitter-flume-source-Vidur1.0.jar TwitterData_

Now lets start with the configuration file for flume

Look for the **.conf** file in the downloaded repository file. This is the configuration file. The configuration file contains all the information about the fields you would need to populate. You will need to provide your credentials, that is the customer id, secret, access token and token secret. You can get these by following the steps given here [https://dev.twitter.com/oauth/overview/application-owner-access-tokens](https://dev.twitter.com/oauth/overview/application-owner-access-tokens)  you can make your own app from the following   [https://apps.twitter.com](https://apps.twitter.com)

Once you get the credentials, replace the code in the .conf file like the following :

- _TwitterAgent.sources.Twitter.consumerKey = 83948202f29fuj9f2f2k_
- _TwitterAgent.sources.Twitter.consumerSecret = 83948202f29fuj9f2f2k_
- _TwitterAgent.sources.Twitter.accessToken = 83948202f29fuj9f2f2k_
- _TwitterAgent.sources.Twitter.accessTokenSecret = 83948202f29fuj9f2f2k_

_You may change the path where the tweets will be dumped in the hdfs by changing the following code:_

- _TwitterAgent.sinks.HDFS.hdfs.path = hdfs://sandbox.hortonworks.com:8020/tmp/flume/twitter/hotel/%Y/%m/%d_

_By default the path is set to:_

- _hdfs://sandbox.hortonworks.com:8020/tmp/flume/twitter/hotel/%Y/%m/%d_

Once you have done the above, you are all set to ingest the twitter data.

Now run the flume agent by executing the following command on your terminal:

- _cd TwitterData_
- _/usr/bin/flume-ng agent --conf ./conf/ -f /root/TwitterData/flume.conf -Dflume.root.logger=DEBUG,console -n TwitterAgent_

# Hive DDL for Twitter Data

You will notice that the twitter repository that you downloaded has two more folders these folders contain support files for sentiment analysis of the twitter data.

It is advisable to create a new folder in HDFS where you can put the support files for the twitter sentiment analysis. This can be done as follows:

- _hadoop fs –mkdir /user/root/TwitterData_

Now copy the supporting files, that is the dictionary and the location files into the new folder that you created in hdfs. Do the following:not sure about the –r below... please check

- _Hadoop fs –cp -r dictionary /user/root/TwitterData/dictionary_
- _Hadoop fs –cp -r time\_zone\_map /user/root/TwitterData/time\_zone\_map_

Please make sure that these files are placed in these folders because these files are used by the hive table formation.

Note that the repository also contains a jar file for serde. It is very important to add this jar file ,  This needs to be done just once, that is the first time the code is executed. It can be done by:

- _hive_

Once the hive shell has started past the code given below:

- _ADD JAR json-serde-1.1.6-SNAPSHOT-jar-with-dependencies.jar;_

Now you are all set to run the Hive DDL script given in the repository folder that you downloaded.

You might need to change the Location of the first table that is created, this table is the **tweets\_raw** table. The location of this table will correspond with the location of the ingested data. You may also need to change the location of the **dictionary** table that will correspond to the place where you have put the dictionary in hdfs. You may also need to change the location of the **time\_zone\_map** table that will correspond to the place where you have put the time\_zone\_map in hdfs.

Everything else that might need to be tweaked has been commented in the ddl file.

# Reference

1. 1. [http://www.thecloudavenue.com/2013/03/analyse-tweets-using-flume-hadoop-and.html](http://www.thecloudavenue.com/2013/03/analyse-tweets-using-flume-hadoop-and.html)
2. 2. [https://gist.github.com/sebsto/19b99f1fa1f32cae5d00](https://gist.github.com/sebsto/19b99f1fa1f32cae5d00)
3. 3. [https://github.com/cloudera/cdh-twitter-example](https://github.com/cloudera/cdh-twitter-example)
4. 4. [http://hortonworks.com/hadoop-tutorial/how-to-refine-and-visualize-sentiment-data/](http://hortonworks.com/hadoop-tutorial/how-to-refine-and-visualize-sentiment-data/)
5. 5. [https://github.com/cloudera/cdh-twitter-example/archive/master.zip](https://github.com/cloudera/cdh-twitter-example/archive/master.zip)
6. 6. [https://dev.twitter.com/oauth/overview/application-owner-access-tokens](https://dev.twitter.com/oauth/overview/application-owner-access-tokens)
7. 7. [https://github.com/vidur89/twitter-repository.git](https://github.com/vidur89/twitter-repository.git)
