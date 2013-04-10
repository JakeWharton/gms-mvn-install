Maven + Google Play Services
============================

The recently released version of Google Play Services presents itself as a library
project with string and attribute resources coupled with a `.jar` in the `libs/` folder
that has been compiled against internal APIs.

While this is convenient for users of IDEs or Ant, it presents a problem for those using
proper build systems (e.g., Maven, Gradle) with dependency management. Inside the `.jar` there are a lot of classes
which reference static attributes on the `com.google.android.gsm.R` class. This means that
 the library must exist in a project which declares that package in its manifest
(thus causing `aapt` to generate an `R.java` for it). While this makes sense, it presents
a problem for users of artifact repositories.

If you use Maven, you can do the following in order to depend on Google Play Services as
a library project:

 1. Copy the `gms-mvn-install.sh` script into the `google-play-services_lib/` folder inside of your SDK.
 2. Execute `./gms-mvn-install.sh` which will install the project into your local Maven repository.
    If you want to deploy the artifacts to a remote repository then execute
    `./gms-mvn-install.sh repo-id repo-url`.

Once completed you can depend on this library project with the following dependency declaration:

```xml
<dependency>
  <groupId>com.google.android.gms</groupId>
  <artifactId>google-play-services</artifactId>
  <version>6</version>
  <type>apklib</type>
</dependency>
```
