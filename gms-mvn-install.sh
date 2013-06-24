#!/bin/bash

set -e

if [ $# -gt 4 ]; then
  echo "Usage: $0 [version] [repo-id repo-url]"
  echo ""
  echo "Installs Google Play Services to your local Maven repo or deploys it to a"
  echo "remote repo if 'repo-id' and 'repo-url' are specified."
  echo ""
  echo "The version can be specified as either a positive integer or a revison"
  echo "number in the format 'r[0-9]+'. Defaults to the version as specified in"
  echo "source.properties."
  echo ""
  exit 1
fi

if echo $1 | egrep -q "^r?[0-9]+$"; then
	VERSION=$1
	shift
elif [ -f source.properties ]; then
	VERSION=`egrep "^Pkg.Revision=[0-9]+$" source.properties | cut -f 2 -d =`
fi

if [ -z "$VERSION" ]; then
  echo "Failed to find a version number, does source.properties exist? If not"
  echo "you can add one as a parameter."
  echo ""
  echo -n "$0 [version]"
  while [ ! -z $1 ]; do
    echo -n "" $1
    shift
  done
  echo ""
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
  <version>$VERSION</version>
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
      <version>$VERSION</version>
    </dependency>
  </dependencies>

  <build>
    <sourceDirectory>src</sourceDirectory>

    <plugins>
      <plugin>
        <groupId>com.jayway.maven.plugins.android.generation2</groupId>
        <artifactId>android-maven-plugin</artifactId>
        <version>3.6.0</version>
        <extensions>true</extensions>
        <configuration>
          <sdk>
            <platform>16</platform>
          </sdk>
          <nativeLibrariesDirectory>ignored</nativeLibrariesDirectory>
        </configuration>
      </plugin>
    </plugins>

    <extensions>
      <extension>
        <groupId>org.apache.maven.wagon</groupId>
        <artifactId>wagon-ftp</artifactId>
        <version>1.0-alpha-6</version>
      </extension>
    </extensions>

  </build>
</project>
EOF

# make javadoc
DIR_LIBPROJECT=`pwd`
cd libs
DIR_JAVADOC=`cat $(find . -name 'google-play-services*.properties') | awk -F= '{print $2}'`
cd $DIR_JAVADOC
zip -qr $DIR_LIBPROJECT/google-play-services-jar-7-javadoc.jar .
cd $DIR_LIBPROJECT

# install locally
mvn org.apache.maven.plugins:maven-install-plugin:2.4:install-file \
  -DgroupId=com.google.android.gms \
  -DartifactId=google-play-services-jar \
  -Dversion=$VERSION \
  -Dpackaging=jar \
  -Dfile=libs/google-play-services.jar \
  -Djavadoc=google-play-services-jar-7-javadoc.jar

mvn clean install

# if a remote is specified, deploy to it as well
if [ ! -z "$REPO_ID" ]; then
  mvn org.apache.maven.plugins:maven-deploy-plugin:2.7:deploy-file \
    -DgroupId=com.google.android.gms \
    -DartifactId=google-play-services-jar \
    -Dversion=$VERSION \
    -Dpackaging=jar \
    -Durl=$REPO_URL \
    -DrepositoryId=$REPO_ID \
    -Dfile=libs/google-play-services.jar \
    -Djavadoc=google-play-services-jar-7-javadoc.jar

  mvn clean deploy -DaltDeploymentRepository=$REPO_ID::default::$REPO_URL
fi
