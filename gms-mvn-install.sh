#!/bin/bash

set -e

if [ $# -ne 0 -a $# -ne 2 ]; then
	echo "Usage: $0 [repo-id repo-url]"
	echo ""
	echo "Installs Google Play Services to your local Maven repo or deploys it to a"
	echo "remote repo if 'repo-id' and 'repo-url' are specified."
	echo ""
	exit 1
fi

REPO_ID="$1"
REPO_URL="$2"

cat > pom.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>com.google.android.gms</groupId>
	<artifactId>google-play-services</artifactId>
	<version>5</version>
	<packaging>apklib</packaging>

	<dependencies>
		<dependency>
			<groupId>com.google.android</groupId>
			<artifactId>android</artifactId>
			<version>4.1.1.4</version>
			<scope>provided</scope>
		</dependency>
		<dependency>
			<groupId>com.google.android.gms</groupId>
			<artifactId>google-play-services-jar</artifactId>
			<version>5</version>
		</dependency>
	</dependencies>

	<build>
		<sourceDirectory>src</sourceDirectory>

		<plugins>
			<plugin>
				<groupId>com.jayway.maven.plugins.android.generation2</groupId>
				<artifactId>android-maven-plugin</artifactId>
				<version>3.5.1</version>
				<extensions>true</extensions>
				<configuration>
					<nativeLibrariesDirectory>ignored</nativeLibrariesDirectory>
				</configuration>
			</plugin>
		</plugins>
	</build>
</project>
EOF

# install locally

mvn org.apache.maven.plugins:maven-install-plugin:2.4:install-file \
	-DgroupId=com.google.android.gms \
	-DartifactId=google-play-services-jar \
	-Dversion=5 \
	-Dpackaging=jar \
	-Dfile=libs/google-play-services.jar

mvn clean install
if [ ! -z "$REPO_ID" ]; then
	# deploy to remote

	mvn org.apache.maven.plugins:maven-deploy-plugin:2.7:deploy-file \
	  -DgroupId=com.google.android.gms \
	  -DartifactId=google-play-services-jar \
	  -Dversion=5 \
	  -Dpackaging=jar \
	  -Durl=$REPO_URL \
	  -DrepositoryId=$REPO_ID \
	  -Dfile=libs/google-play-services.jar

	mvn clean deploy -DaltDeploymentRepository=$REPO_ID::default::$REPO_URL
fi
