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

# Update rstudio:
sudo rstudio-server active-sessions
sudo rstudio-server offline
wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2022.02.0-443-amd64.deb
sudo gdebi rstudio-server-2022.02.0-443-amd64.deb
sudo rstudio-server restart
sudo rstudio-server online

# Install libgeos for SeuratObject_4.1.0
sudo apt install libgeos-dev
# Install cmake for ggpubr
sudo apt install cmake
# Install for tidyverse:
sudo apt-get update
sudo apt-get install libfontconfig1-dev
sudo apt-get install libharfbuzz-dev libfribidi-dev
sudo apt-get install libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

# Update the shiny app
# Stop the service:
sudo systemctl stop shiny-server.service
# Pull the repo
sudo su - shiny
cd /data/shiny-server/apps/omeroDubouleUploadAnnotate/
git pull origin main
# Restart the service
exit
sudo systemctl start shiny-server

# Update all packages (2023-04-05)
sudo apt-get update
# W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: https://repos.influxdata.com/ubuntu focal InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY D8FF8E1F7DF8B07E
# W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: https://packages.grafana.com/oss/deb stable InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 9E439B102CF3C0C6
# W: Failed to fetch https://packages.grafana.com/oss/deb/dists/stable/InRelease  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 9E439B102CF3C0C6
# W: Failed to fetch https://repos.influxdata.com/ubuntu/dists/focal/InRelease  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY D8FF8E1F7DF8B07E
# W: Some index files failed to download. They have been ignored, or old ones used instead.

sudo apt-get upgrade
# This updates R:
# Get:4 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-base-core 4.2.3-1.2004.0 [26.2 MB]                     
# Get:10 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-cluster 2.1.4-1.2004.0 [550 kB]                         
# Get:13 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-foreign 0.8.82-1.2004.0 [238 kB]     
# Get:19 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-lattice 0.20-45-3.2004.0 [1,133 kB]  
# Get:46 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-nlme 3.1.162-1.2004.0 [2,250 kB]
# Get:66 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-matrix 1.5-1-1.2004.0 [3,703 kB]
# Get:93 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-mgcv 1.8-42-1cran1.2004.0 [3,180 kB]
# Get:103 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-survival 3.5-5-1cran1.2004.0 [5,927 kB]
# Get:114 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-rpart 4.1.19-1.2004.0 [911 kB]
# Get:115 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-mass 7.3-58.3-1.2004.0 [1,122 kB]    
# Get:116 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-class 7.3-21-1.2004.0 [87.7 kB]       
# Get:117 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-nnet 7.3-18-1.2004.0 [112 kB]   
# Get:127 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-cran-codetools 0.2-19-1cran1.2004.0 [90.6 kB]
# Get:131 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-base 4.2.3-1.2004.0 [45.5 kB]
# Get:137 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-recommended 4.2.3-1.2004.0 [2,780 B]
# Get:138 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-base-dev 4.2.3-1.2004.0 [4,492 B]              
# Get:139 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-base-html 4.2.3-1.2004.0 [93.3 kB]         
# Get:140 https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/ r-doc-html 4.2.3-1.2004.0 [588 kB]

## Relative to /etc/issue.net modified by SV-IT
# Installing new version of config file /etc/issue ...

# Configuration file '/etc/issue.net'
#  ==> Modified (by you or by a script) since installation.
#  ==> Package distributor has shipped an updated version.
#    What would you like to do about it ?  Your options are:
#     Y or I  : install the package maintainer's version
#     N or O  : keep your currently-installed version
#       D     : show the differences between the versions
#       Z     : start a shell to examine the situation
#  The default action is to keep your current version.
# *** issue.net (Y/I/N/O/D/Z) [default=N] ? N

# How to know if reboot is required?
# https://askubuntu.com/questions/164/how-can-i-tell-from-the-command-line-whether-the-machine-requires-a-reboot
ls /var/run/reboot-required
# The file exists so I need to reboot
# Before that I will update rstudioserver
# https://support.posit.co/hc/en-us/articles/216079967-Upgrading-RStudio-Workbench-or-RStudio-Server
sudo rstudio-server active-sessions
# No active session
# No need to do
# sudo rstudio-server suspend-all
sudo rstudio-server offline
wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2023.03.0-386-amd64.deb

sudo gdebi rstudio-server-2023.03.0-386-amd64.deb
# Do you want to install the software package? [y/N]:y

# It seems that the installation already started it
# sudo rstudio-server restart
sudo rstudio-server online

# I worked but you loose all your opened files.

# I try to reboot
sudo reboot

# After a while I manage to ssh but none of the services are up:
# I check galaxy:
sudo systemctl status galaxy.service 
# ● galaxy.service - Galaxy
#      Loaded: loaded (/etc/systemd/system/galaxy.service; enabled; vendor preset: enabled)
#      Active: active (running) since Wed 2023-04-05 07:21:50 CEST; 2min 41s ago
#    Main PID: 1494 (uwsgi)
#       Tasks: 46 (limit: 463941)
#      Memory: 1.4G (limit: 32.0G)
#         CPU: 42.220s
#      CGroup: /system.slice/galaxy.service
#              ├─1494 /data/galaxy/galaxy/venv/bin/python /data/galaxy/galaxy/venv/bin/uwsgi --yaml /data/galaxy/galaxy/config/galaxy>
#              ├─3685 /data/galaxy/galaxy/venv/bin/python /data/galaxy/galaxy/venv/bin/uwsgi --yaml /data/galaxy/galaxy/config/galaxy>
#              ├─3688 /data/galaxy/galaxy/venv/bin/python /data/galaxy/galaxy/venv/bin/uwsgi --yaml /data/galaxy/galaxy/config/galaxy>
#              └─3689 /data/galaxy/galaxy/venv/bin/python /data/galaxy/galaxy/venv/bin/uwsgi --yaml /data/galaxy/galaxy/config/galaxy>

# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.jobs.handler INFO 2023-04-05 07:23:07,784 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:W>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.web_stack.transport INFO 2023-04-05 07:23:07,788 [pN:main.job-handlers.1,p:3688,w:0,m>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.web_stack.transport INFO 2023-04-05 07:23:07,788 [pN:main.job-handlers.1,p:3688,w:0,m>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.queue_worker INFO 2023-04-05 07:23:07,788 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:M>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.queue_worker INFO 2023-04-05 07:23:07,790 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:M>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.app INFO 2023-04-05 07:23:07,868 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:MainThread>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.web_stack INFO 2023-04-05 07:23:07,868 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:Main>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.queue_worker INFO 2023-04-05 07:23:07,877 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:T>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.queue_worker INFO 2023-04-05 07:23:07,908 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:T>
# Apr 05 07:23:07 updubsrv1 uwsgi[3688]: galaxy.queue_worker DEBUG 2023-04-05 07:23:07,908 [pN:main.job-handlers.1,p:3688,w:0,m:1,tN:>

# So I would say it is more nginx
sudo systemctl status nginx.service 
# ● nginx.service - A high performance web server and a reverse proxy server
#      Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
#      Active: failed (Result: exit-code) since Wed 2023-04-05 07:21:50 CEST; 4min 25s ago
#        Docs: man:nginx(8)
#     Process: 1496 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=1/FAILURE)

# Apr 05 07:21:50 updubsrv1 systemd[1]: Starting A high performance web server and a reverse proxy server...
# Apr 05 07:21:50 updubsrv1 nginx[1496]: nginx: [warn] duplicate value "TLSv1.2" in /etc/nginx/conf.d/ssl.conf:6
# Apr 05 07:21:50 updubsrv1 nginx[1496]: nginx: [warn] duplicate value "TLSv1.3" in /etc/nginx/conf.d/ssl.conf:6
# Apr 05 07:21:50 updubsrv1 nginx[1496]: nginx: [emerg] host not found in upstream "training.galaxyproject.org" in /etc/nginx/sites-enabled/galaxy
# Apr 05 07:21:50 updubsrv1 nginx[1496]: nginx: configuration file /etc/nginx/nginx.conf test failed
# Apr 05 07:21:50 updubsrv1 systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
# Apr 05 07:21:50 updubsrv1 systemd[1]: nginx.service: Failed with result 'exit-code'.
# Apr 05 07:21:50 updubsrv1 systemd[1]: Failed to start A high performance web server and a reverse proxy server.

# Apparently training.galaxyproject.org was unresponsive at the time nginx started.

sudo systemctl restart nginx.service 

# Everything is back to normal!
# romero.gateway and Rjava are working while they were built on R 4.1.1...

# I checked there was nothing more to install and then
sudo apt autoremove

# I realized that /usr/local/lib/R/site-library/ is writable by everyone.
# Therefore packages have been added by everyone.
# Then another user cannot update the package installed by someone else.
# I need to change this.

# After R upgrade, a good way can be: update.packages(checkBuilt = TRUE, ask = FALSE)
# I run 
sudo R
install.packages(c("BiocManager", "blob", "brew", "brio", "bslib", "cachem", "callr", "cli", "clipr", "colorspace", "commonmark", "cpp11", "crayon", "credentials", "curl", "desc", "devtools", "digest", "evaluate", "fansi", "farver", "fastmap", "FNN", "fontawesome", "fs", "gert", "ggplot2", "gh", "gitcreds", "glue", "gtable", "highr", "hms", "htmltools", "httpuv", "httr", "isoband", "jsonlite", "knitr", "lifecycle", "magrittr", "Matrix", "memoise", "openssl", "parallelly", "pillar", "pkgbuild", "pkgload", "plyr", "processx", "ps", "purrr", "RColorBrewer", "Rcpp", "RcppTOML", "RCurl", "remotes", "reshape", "rlang", "roxygen2", "rprojroot", "RSQLite", "rstudioapi", "rversions", "sass", "scales", "sessioninfo", "shiny", "sourcetools", "stringi", "stringr", "sys", "testthat", "tibble", "usethis", "utf8", "vctrs", "viridisLite", "waldo", "whisker", "withr", "xfun", "XML", "xml2", "yaml", "zip"))
update.packages(checkBuilt = TRUE, ask = FALSE)
# Update all BiocManager packages:
BiocManager::install()
# Error: Bioconductor version '3.13' requires R version '4.1'; use
#   `BiocManager::install(version = '3.16')` with R version 4.2; see
#   https://bioconductor.org/install
BiocManager::install(version = '3.16')
# Upgrade 27 packages to Bioconductor version '3.16'? [y/n]: y

# With another terminal I check which libraries have not been updated today:
ls -alh /usr/local/lib/R/site-library/ | grep -v "Apr  5"
# I have romero.gateway, spatstat.core, usefulLDfunctions.
# I reinstall them manually:
version <- "0.4.11"
install.packages(paste0("https://github.com/ome/rOMERO-gateway/releases/download/v", version, "/romero.gateway_", version, ".tar.gz"), type='source', repos = NULL)
devtools::install_github("lldelisle/usefulLDfunctions")
install.packages('spatstat.core')
# Installing package into ‘/usr/local/lib/R/site-library’
# (as ‘lib’ is unspecified)
# Warning message:
# package ‘spatstat.core’ is not available for this version of R

# A version of this package for your version of R might be available elsewhere,
# see the ideas at
# https://cran.r-project.org/doc/manuals/r-patched/R-admin.html#Installing-packages 
# So I remove it
remove.packages("spatstat.core")
# I have 3 packages installed by ldelisle
# I reinstall them with sudo:
install.packages("ragg")
install.packages(c("systemfonts", "textshaping"))

# Now I remove write access to /usr/local/lib/R/site-library/
sudo chmod o-w /usr/local/lib/R/site-library/

# I install commonly used packages:
install.packages("Seurat")
install.packages(c("dplyr", "plyr"))
install.packages("ggpubr")
install.packages("ggh4x")
install.packages("pheatmap")
BiocManager::install("DESeq2")
install.packages("readxl")
install.packages("readxl")
install.packages("DWLS")
BiocManager::install("demuxmix")


# Reinstall last version of R:
sudo apt-get update
# W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: https://repos.influxdata.com/ubuntu focal InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY D8FF8E1F7DF8B07E
# W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: https://packages.grafana.com/oss/deb stable InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 9E439B102CF3C0C6
# W: Failed to fetch https://packages.grafana.com/oss/deb/dists/stable/InRelease  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 9E439B102CF3C0C6
# W: Failed to fetch https://repos.influxdata.com/ubuntu/dists/focal/InRelease  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY D8FF8E1F7DF8B07E
# W: Some index files failed to download. They have been ignored, or old ones used instead.

sudo apt-get upgrade
# This updates R

# How to know if reboot is required?
# https://askubuntu.com/questions/164/how-can-i-tell-from-the-command-line-whether-the-machine-requires-a-reboot
ls /var/run/reboot-required
# The file exists so I need to reboot
sudo reboot

# Apparently training.galaxyproject.org was unresponsive at the time nginx started.

sudo systemctl restart nginx.service 



sudo R
update.packages(checkBuilt = TRUE, ask = FALSE)
BiocManager::install(version = '3.17')
version <- "0.4.12"
install.packages(paste0("https://github.com/ome/rOMERO-gateway/releases/download/v", version, "/romero.gateway_", version, ".tar.gz"), type='source', repos = NULL)
library(romero.gateway)
# I need to download OMERO Java libraries
devtools::install_github("lldelisle/usefulLDfunctions")

# 20230705 Installing velocytoR
sudo su -
R
library(devtools)
install_github("velocyto-team/velocyto.R")
# I don't update anything
# ERROR: dependency ‘pcaMethods’ is not available for package ‘velocyto.R’
BiocManager::install("pcaMethods")
# I don't update old packages
install_github("velocyto-team/velocyto.R")
# I don't update
# /usr/bin/ld: cannot find -lboost_filesystem
# /usr/bin/ld: cannot find -lboost_system
# collect2: error: ld returned 1 exit status
# make: *** [/usr/share/R/share/make/shlib.mk:10: velocyto.R.so] Error 1
# ERROR: compilation failed for package ‘velocyto.R’
quit()

apt-get install libboost-filesystem-dev libboost-system-dev

R
library(devtools)
install_github("velocyto-team/velocyto.R")
quit()


sudo apt-get install libcairo2-dev

sudo R
install.packages('ggrastr')

# 20231107 install h5py and ipython:
sudo apt-get -y install python3-h5py ipython3

# 20231128 auto mount at boot:
# Update /etc/fstab
# Update all except r packages:
sudo apt-get update
sudo apt list --upgradable
# All r packages start with r-
for package in $(sudo apt list --upgradable | grep "^r-" | cut -d "/" -f 1); do sudo apt-mark hold $package; done
sudo apt-mark showhold
# When I want to remove them from hold:
# sudo apt-mark showhold
sudo apt-get update
# ...
# update-initramfs: Generating /boot/initrd.img-5.15.0-89-generic
# I: The initramfs will attempt to resume from /dev/dm-1
# I: (/dev/mapper/vgubuntu-swap_1)
# I: Set the RESUME variable to override this.
# update-initramfs: Generating /boot/initrd.img-5.15.0-71-generic
# I: The initramfs will attempt to resume from /dev/dm-1
# I: (/dev/mapper/vgubuntu-swap_1)
# I: Set the RESUME variable to override this.
# ...                                        
# Installing new version of config file /etc/grub.d/20_linux_xen ...
# update-rc.d: warning: start and stop actions are no longer supported; falling back to defaults
# ...
# pam-auth-update: Local modifications to /etc/pam.d/common-*, not updating.
# pam-auth-update: Run pam-auth-update --force to override.
# ...
# update-initramfs: Generating /boot/initrd.img-5.15.0-89-generic
# I: The initramfs will attempt to resume from /dev/dm-1
# I: (/dev/mapper/vgubuntu-swap_1)
# I: Set the RESUME variable to override this.

# Check if reboot is required
ls /var/run/reboot-required

# Reboot

# Install scvelo
sudo su - galaxy
/data/galaxy/galaxy/var/dependencies/_conda/bin/python /data/galaxy/galaxy/var/dependencies/_conda/bin/conda create --override-channels --channel conda-forge -p /data/galaxy/galaxy/var/dependencies/_conda/envs/scVelo0.3.1 python=3.11 mamba
. '/data/galaxy/galaxy/var/dependencies/_conda/bin/activate' /data/galaxy/galaxy/var/dependencies/_conda/envs/scVelo0.3.1
mamba install --override-channels --channel conda-forge scvelo=0.3.1

# Install monocle3
sudo R
devtools::install_github('cole-trapnell-lab/monocle3')                                                              # ERROR: dependencies ‘sf’, ‘spdep’ are not available for package ‘monocle3’   
BiocManager::install('sf')
# Configuration failed because libudunits2.so was not found.
# I need to install sudo apt-get install libudunits2-dev
BiocManager::install('sf')
# configure: error: gdal-config not found or not executable.
# sudo apt-get install libgdal-dev 
BiocManager::install('sf')
BiocManager::install('spdep')
devtools::install_github('cole-trapnell-lab/monocle3')
# Error in loadNamespace(j <- i[[1L]], c(lib.loc, .libPaths()), versionCheck = vI[[j]]) : 
#   namespace ‘igraph’ 1.4.2 is being loaded, but >= 1.5.0 is required

# Install gsl
install.packages("gsl")
# configure: error: gsl-config not found, is GSL installed?
# I tried sudo apt-get install libgsl23
# Same issue, I tried sudo apt-get install libgsl-dev
