# Dependencies for RStudio:
# For devtools:
sudo apt-get install libcurl4-openssl-dev libssl-dev libxml2-dev
# For hdf5r
sudo apt-get install libhdf5-dev
# Install curl:
sudo apt-get install curl

# Install last version of aws:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# The IT installed RShiny
# I need to have rJava working
sudo R CMD javareconf
# Java interpreter : /usr/lib/jvm/default-java/bin/java
# Java version     : 11.0.11
# Java home path   : /usr/lib/jvm/default-java
# Java compiler    : not present
# Java headers gen.: 
# Java archive tool: 

# trying to compile and link a JNI program 
# detected JNI cpp flags    : 
# detected JNI linker flags : -L$(JAVA_HOME)/lib/server -ljvm
# gcc -std=gnu99 -I"/usr/share/R/include" -DNDEBUG      -fpic  -g -O2 -fdebug-prefix-map=/build/r-base-QwogzP/r-base-4.1.1=. -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g  -c conftest.c -o conftest.o
# conftest.c:1:10: fatal error: jni.h: No such file or directory
#     1 | #include <jni.h>
#       |          ^~~~~~~
# compilation terminated.
# make: *** [/usr/lib/R/etc/Makeconf:168: conftest.o] Error 1
# Unable to compile a JNI program


# JAVA_HOME        : /usr/lib/jvm/default-java
# Java library path: 
# JNI cpp flags    : 
# JNI linker flags : 
# Updating Java configuration in /usr/lib/R
# Done.
# I try to install rJava but I get:
# configure: error: Java Development Kit (JDK) is missing or not registered in R
# Only JRE was installed:
sudo apt-get install openjdk-11-jdk
sudo R CMD javareconf
# Now installation of rJava worked
# I also install jpeg and
# romero-gateway:
# version <- "0.4.11"

# if ( ! "romero.gateway" %in% installed.packages() || installed.packages()["romero.gateway", "Version"] != version){
#   install.packages(paste0("https://github.com/ome/rOMERO-gateway/releases/download/v", version, "/romero.gateway_", version, ".tar.gz"), type='source', repos = NULL)
# }
# I load it to install the libraries:
# library(romero.gateway)
# I installed future

# I need to create a conda env with omero.
sudo su - galaxy
/data/galaxy/galaxy/var/dependencies/_conda/bin/conda create -n omero  -c ome python=3.6 zeroc-ice36-python omero-py pandas
