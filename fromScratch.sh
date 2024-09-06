#!/usr/bin/bash

# Using virtualbox
# Use ubuntu live server
# Use 25GB
# Forwarding the port:
# On virtual box: Settings, Network, NAT Advanced Port Forwarding Host: 2230 Guest 22
# I also need to forward the port 80 for galaxy interface and 3000 for graphana
# If it is not the real machine, change /etc/hosts
# Set the IP of the VM to galaxyduboule.epfl.ch

port=22
guest=galaxyduboule.epfl.ch
username=ldelisle

# From the host copy the ssh key:
ssh-copy-id -p ${port} ${username}@${guest}

# ssh on the machine
ssh -p ${port} ${username}@${guest}
# Copy the ssh to helvetios:
ssh-keygen 
ssh-copy-id helvetios.epfl.ch
# Get the last version of the DB:
scp helvetios.epfl.ch:/work/updub/2021-03-09.tar /tmp/
# Give access to postgres
chmod 777 /tmp/2021-03-09.tar
# become root:
sudo su -
# Put the password
# Create the symlink for mount_s3
mkdir /slipstream
ln -s /data/mount_s3 /slipstream/mount_s3
# Create the folder for postgresql
mkdir -p /data/postgresql
ln -s /data/postgresql /var/lib/postgresql
# Update the databases
# apt-get update
# Upgrade
# apt-get upgrade
# Restart
# reboot now
# This disconnect you

## Start ansible:

# Install dependencies (use --force if you updated it);
ansible-galaxy install -p roles/ --force -r requirements.yml 

# I think that first you need to put slurm:
ansible-playbook slurm.yml -K
# If you need to upload a postgres db
# First install prostgres
ansible-playbook postgres_only.yml -K
# The database was dump with:
# /usr/lib/postgresql/9.3/bin/pg_dump -d galaxy_production -F t -b -f ~/20200616.tar
# -d is the name of the db
# -F is the format (t = tar)
# -b blobs include large objects
# Ssh:
ssh -p $port ${username}@${guest}
# Become postgres
sudo su - postgres
# Restore
pg_restore --dbname=galaxy --verbose /tmp/2021-03-09.tar
# pg_restore: connecting to database for restore
# pg_restore: creating SCHEMA "public"
# pg_restore: while PROCESSING TOC:
# pg_restore: from TOC entry 7; 2615 2200 SCHEMA public postgres
# pg_restore: error: could not execute query: ERROR:  schema "public" already exists
# ...
# pg_restore: error: could not execute query: ERROR:  role "galaxyftp" does not exist
# ...
# pg_restore: warning: errors ignored on restore: 2

# Prepare the backup sync:
ssh-keygen 
ssh-copy-id ldelisle@helvetios.epfl.ch
ssh -q -t ldelisle@helvetios.epfl.ch "mkdir -p /work/updub/backups_galaxyDB/current"
# Logout as postgres
exit
# Logout
exit

# Then galaxy
ansible-playbook galaxy.yml -K
# Then grafana
ansible-playbook monitoring.yml -K
# Again galaxy
ansible-playbook galaxy.yml -K

# I need to go to grafana page and sign in
# Put the dashboads

# # To be able to make pictures with grafana. Not sure it is useful...
# # ssh:
# ssh -p $port ${username}@${guest}
# sudo grafana-cli plugins install grafana-image-renderer
# sudo apt-get install cups fonts-liberation libx11-6 libx11-xcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrender1 libxtst6 libglib2.0-0 libnss3 libcups2  libdbus-1-3 libxss1 libxrandr2 libgtk-3-0 libgtk-3-0 libasound2
# sudo systemctl restart grafana-server.service 
# # I can get a picture at http://galaxyduboule.epfl.ch:3000/render/d/c61Pj2yGz/main?orgId=1&width=1000&height=800&autofitpanels
# # curl -H "Authorization: Bearer {{ api_grafana }}"  "http://localhost:3000/render/d/c61Pj2yGz/main?orgId=1&width=1000&height=800&autofitpanels" > test.png

# I first need to clean the tools:
# conda create -n bioblend bioblend ephemeris
conda activate bioblend
# I get the API key
apikey=""
# Then I clean
python tools/clean_all_installed_tools.py $apikey
# I restart galaxy
ssh -p ${port} ${username}@${guest}
sudo systemctl restart galaxy
# I still have 25 repo installed.
# And still a lot in currently installing...
# I manually click on Deactivated
# It goes back to 15
# I click again until no more
# I check what is happening when uninstalling:
# sudo journalctl -fu galaxy
# Mär 10 14:23:27 updubsrv1 uwsgi[36739]: galaxy.tool_shed.galaxy_install.installed_repository_manager DEBUG 2021-03-10 14:23:27,994 [p:36739,w:1,m:0] [uWSGIWorker1Core0] Error removing repository installation directory /data/galaxy/galaxy/var/shed_tools/toolshed.g2.bx.psu.edu/repos/iuc/package_bedtools_2_24/39b86c1e267d: [Errno 2] No such file or directory: '/data/galaxy/galaxy/var/shed_tools/toolshed.g2.bx.psu.edu/repos/iuc/package_bedtools_2_24/39b86c1e267d'
# Mär 10 14:23:27 updubsrv1 uwsgi[36739]: galaxy.tool_shed.galaxy_install.installed_repository_manager DEBUG 2021-03-10 14:23:27,994 [p:36739,w:1,m:0] [uWSGIWorker1Core0] Repository directory does not exist on disk, marking as uninstalled.
# Mär 10 14:23:27 updubsrv1 uwsgi[36739]: 128.179.254.231 - - [10/Mar/2021:14:23:27 +0200] "DELETE /api/tool_shed_repositories?tool_shed_url=https://toolshed.g2.bx.psu.edu/&name=package_bedtools_2_24&owner=iuc&changeset_revision=3416a1d4a582& HTTP/1.1" 200 - "https://galaxyduboule.epfl.ch/admin/toolshed" "Mozilla/5.0 (X11; Linux x86_64; rv:86.0) Gecko/20100101 Firefox/86.0"
# I tried to create the directory but it did not help...
# I tried to clean the metadata:
# galaxy.tool_shed.galaxy_install.metadata.installed_repository_metadata_manager DEBUG 2021-03-10 14:29:04,534 [p:40323,w:1,m:0] [uWSGIWorker1Core0] Metadata has been reset on repository package_matplotlib_1_2.
# Mär 10 14:29:04 updubsrv1 uwsgi[40323]: galaxy.tools.toolbox.base WARNING 2021-03-10 14:29:04,647 [p:40323,w:1,m:0] [uWSGIWorker1Core0] '/slipstream/galaxy/production/config/shed_tool_conf.xml' not among installable tool config files (/data/galaxy/galaxy/var/config/shed_tool_conf.xml, /data/galaxy/galaxy/var/config/migrated_tools_conf.xml)


# workflow-to-tools -w tools/wf_to_transfer/*  -o tools/tools_in_wf_to_transfer.yml
# Then I updated section name and the version when not available
# reported the tools without the version in the my_tools.yml

# Reinstallation:
shed-tools install -g https://galaxyduboule.epfl.ch -a $apikey -t tools/my_tools.yml 
shed-tools install -g https://galaxyduboule.epfl.ch -a $apikey -t tools/tools_in_wf.yml
shed-tools install -g https://galaxyduboule.epfl.ch -a $apikey -t tools/data_managers_tools.yml 
# I need to restart galaxy
ssh -p $port ${username}@${guest}
sudo systemctl restart galaxy
# I also need to make shed_data_manager_conf.xml downloadable
sudo cp /data/galaxy/galaxy/var/config/shed_data_manager_conf.xml /tmp/
sudo chmod 777 /tmp/shed_data_manager_conf.xml 
exit

scp -P $port ${username}@${guest}:/tmp/shed_data_manager_conf.xml tools/
# First Fetching new genomes
# Run make_fetch.py to build the fetch manager config file for ephemeris
python tools/make_fetch.py -g tools/genomes.yml -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -o tools/fetch.yml
# Fetch the genomes
run-data-managers --config tools/fetch.yml -g https://galaxyduboule.epfl.ch -a $apikey
# I got errors:
# ftplib.error_perm: 530 Access Denied - You have too many open sessions already!
# I needed to run it multiple times.

# I don't know if I need to restart galaxy...

# Building new indices
# Run the make_dm_genomes.py script to create the list of index builders and genomes and pass it to ephemeris
python tools/fromIDC_Simon/make_dm_genomes.py -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -g tools/genomes.yml -o tools/dm_genomes.yml
run-data-managers --config tools/dm_genomes.yml -g https://galaxyduboule.epfl.ch -a $apikey
# I have an issue with bowtie2:
# /data/galaxy/galaxy/var/dependencies/_conda/envs/__bowtie2@2.3.5/bin/bowtie2-build-s: error while loading shared libraries: libtbb.so.2: cannot open shared object file: No such file or directory
# Error building index.
# When I try:
# . /data/galaxy/galaxy/var/dependencies/_conda/bin/activate /data/galaxy/galaxy/var/dependencies/_conda/envs/__bowtie2@2.3.5
# bowtie2 --help
# Possible unintended interpolation of @2 in string at /data/galaxy/galaxy/var/dependencies/_conda/envs/__bowtie2@2.3.5/lib/5.32.0/x86_64-linux-thread-multi/Config_heavy.pl line 260.
# /data/galaxy/galaxy/var/dependencies/_conda/envs/__bowtie2@2.3.5/bin/bowtie2-align-s: error while loading shared libraries: libtbb.so.2: cannot open shared object file: No such file or directory
# (ERR): Description of arguments failed!
# Exiting now ...
# I try to uninstall and reinstall.
# Did not fixed but
# conda install -y --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults tbb=2019.9
# Fixed it
# For the datamanager of rnastar old version:
# I need to change the files in /data/galaxy/galaxy/var/shed_tools/toolshed.g2.bx.psu.edu/repos/iuc/data_manager_star_index_builder/6ef6520f14fc/data_manager_star_index_builder/data_manager/
# Both py and xml
# To make it work for release_20.9
scp tools/data_manager_star_index_builder/* galaxyduboule.epfl.ch:/tmp/
# Then as galaxy user on the remote:
cp /tmp/rna_star_index_builder* /data/galaxy/galaxy/var/shed_tools/toolshed.g2.bx.psu.edu/repos/iuc/data_manager_star_index_builder/6ef6520f14fc/data_manager_star_index_builder/data_manager/





# What does not work:
# The samtools 1.2 needed for hicup
sudo apt-get install libncurses5
# The samtools 1.8 needed for filter
sudo su - galaxy
. '/data/galaxy/galaxy/var/dependencies/_conda/bin/activate' '/data/galaxy/galaxy/var/dependencies/_conda/envs/__samtools@1.8'
conda install -y "openssl<1.1"
conda deactivate
# The bowtie2.3.4
. '/data/galaxy/galaxy/var/dependencies/_conda/bin/activate' '/data/galaxy/galaxy/var/dependencies/_conda/envs/mulled-v1-65d5efe4f1b69ab7166d1a5a5616adebe902133ea3e4c189d87d7de2e21ddc17/'
conda install -y --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults tbb=2019.9
# Same with bowtie 2.4.1:
. '/data/galaxy/galaxy/var/dependencies/_conda/bin/activate' '/data/galaxy/galaxy/var/dependencies/_conda/envs/mulled-v1-2c9d0d73d81f016cd458c97e185f638410841f3ecf7ae79158d90e0d58249513'
conda install -y --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults tbb=2019.9
# For the old picard which uses java:
sudo apt-get install default-jre
# Written for python2:
# I will substitute the python file:
scp tools/picard_wrapper.py galaxyduboule.epfl.ch:/tmp/
# Then as galaxy user on the remote:
cp /tmp/picard_wrapper.py /data/galaxy/galaxy/var/shed_tools/toolshed.g2.bx.psu.edu/repos/devteam/picard/bf1c3f9f8282/picard/picard_wrapper.py

# macs2 environment often fail but sometimes it works...

# I needed to go to the admin interface to install a lot of dependencies.


# Rebuild the useful_LD
python tools/create_History_with_Fasta_Length.py $apikey
python tools/create_History_with_UsefulFiles.py $apikey

# Install tree
sudo apt-get install tree

# 202110 update:
sudo apt-get update
sudo apt-get upgrade

# Clean:
sudo apt autoremove

##################
### BIG UPDATE ###
##################

# Follow: https://training.galaxyproject.org/training-material/topics/admin/faqs/galaxy-update-22.05.html

# First I stop galaxy
# On the galaxy machine
sudo systemctl stop galaxy

# Then I change the release and run the playbook
# Locally
ansible-playbook galaxy.yml -K

# I get an error at the build client stage but I ignore it
# I do the migration manually
# On the galaxy machine
sudo su - galaxy

GALAXY_CONFIG_FILE=/data/galaxy/galaxy/config/galaxy.yml sh /data/galaxy/galaxy/server/manage_db.sh -c /data/galaxy/galaxy/config/galaxy.yml upgrade
# Traceback (most recent call last):
#   File "/data/galaxy/galaxy/server/./scripts/db.py", line 11, in <module>
#     from galaxy.model.migrations.dbscript import ParserBuilder
#   File "/data/galaxy/galaxy/server/lib/galaxy/model/__init__.py", line 43, in <module>
#     import sqlalchemy
# ModuleNotFoundError: No module named 'sqlalchemy'

# Try to activate the venv
. /data/galaxy/galaxy/venv/bin/activate
GALAXY_CONFIG_FILE=/data/galaxy/galaxy/config/galaxy.yml sh /data/galaxy/galaxy/server/manage_db.sh -c /data/galaxy/galaxy/config/galaxy.yml upgrade

# INFO:alembic.runtime.migration:Context impl PostgresqlImpl.
# INFO:alembic.runtime.migration:Will assume transactional DDL.
# INFO:alembic.runtime.migration:Context impl PostgresqlImpl.
# INFO:alembic.runtime.migration:Will assume transactional DDL.
