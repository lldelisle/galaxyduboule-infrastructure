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

# Change the config files the way I think is good to be compatible with 23.0
# Using git-gat Step-4

# Install dependencies
ansible-galaxy install -p roles/ --force -r requirements.yml

# Run playbook
ansible-playbook galaxy.yml -K

# Stopped it in the middle as I forgot to mv the venv
# On galaxy server
sudo mv /data/galaxy/galaxy/venv/ /data/galaxy/galaxy/venv-old

# Locally
# Run playbook
ansible-playbook galaxy.yml -K

# Everything seems to work except:
# TASK [galaxyproject.nginx : Fail due to previous configuration installation or validation errors] *****************************************************************************************************************************
# fatal: [galaxyduboule.epfl.ch]: FAILED! => {"changed": false, "msg": "The new nginx configuration failed to install or validate, so the previous configuration has been restored. Please investigate the errors above for more information."}

# I change the galaxy.j2 and the playbook goes to the end.

# Check the status with
# On the galaxy machine

sudo galaxyctl status
# Dynamic handlers are configured in Gravity but Galaxy is not configured to assign jobs to handlers dynamically, so these handlers will not handle jobs. Set the job handler assignment method in the Galaxy job configuration to `db-skip-locked` or `db-transaction-isolation` to fix this.
#   UNIT LOAD ACTIVE SUB DESCRIPTION
# 0 loaded units listed.
# To show all installed unit files use 'systemctl list-unit-files'.

# I convert my job_conf.xml.j2 to yaml in galaxyservers.yml group_vars
# Run the playbook, everything looks fine

# I check the status
sudo galaxyctl status
#   UNIT LOAD ACTIVE SUB DESCRIPTION
# 0 loaded units listed.
# To show all installed unit files use 'systemctl list-unit-files'.

# Try what Helena suggested:
sudo galaxyctl -c /data/galaxy/galaxy/config/galaxy.yml update
# Adding systemd unit galaxy-gunicorn.service
# Adding systemd unit galaxy-celery.service
# Adding systemd unit galaxy-celery-beat.service
# Adding systemd unit galaxy-handler@.service
# Adding systemd unit galaxy.target
# Created symlink /etc/systemd/system/multi-user.target.wants/galaxy.target → /etc/systemd/system/galaxy.target.
sudo rm /etc/systemd/system/galaxy.service

# Check the status:
sudo galaxyctl status
#   UNIT                       LOAD   ACTIVE   SUB  DESCRIPTION
#   galaxy-celery-beat.service loaded inactive dead Galaxy celery-beat
#   galaxy-celery.service      loaded inactive dead Galaxy celery
#   galaxy-gunicorn.service    loaded inactive dead Galaxy gunicorn
#   galaxy-handler@0.service   loaded inactive dead Galaxy handler (process 0)
#   galaxy-handler@1.service   loaded inactive dead Galaxy handler (process 1)
#   galaxy.target              loaded inactive dead Galaxy

# LOAD   = Reflects whether the unit definition was properly loaded.
# ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
# SUB    = The low-level unit activation state, values depend on unit type.

# 6 loaded units listed.
# To show all installed unit files use 'systemctl list-unit-files'.

# Try to restart
sudo galaxyctl restart galaxy
# Warning: Not a known instance or service name: galaxy
# Error: No provided names are known instance or service names
sudo galaxyctl restart galaxy.target
# Warning: Not a known instance or service name: galaxy.target
# Error: No provided names are known instance or service names

# The command line was simpler:
sudo galaxyctl restart

# Then I checked what was happening:
sudo galaxyctl restart
# And I noticed:
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]: Failed to initialize Galaxy application
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]: Traceback (most recent call last):
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:   File "/data/galaxy/galaxy/server/lib/galaxy/jobs/runners/drmaa.py", line 70, in __init__
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:     drmaa = __import__("drmaa")
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:   File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/drmaa/__init__.py", line 65, in <module>
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:     from .session import JobInfo, JobTemplate, Session
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:   File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/drmaa/session.py", line 39, in <module>
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:     from drmaa.helpers import (adapt_rusage, Attribute, attribute_names_iterator,
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:   File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/drmaa/helpers.py", line 36, in <module>
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:     from drmaa.wrappers import (drmaa_attr_names_t, drmaa_attr_values_t,
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:   File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/drmaa/wrappers.py", line 52, in <module>
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]:     raise RuntimeError(('Could not find drmaa library.  Please specify its ' +
# Sep 06 16:15:14 updubsrv1 galaxyctl[3275401]: RuntimeError: Could not find drmaa library.  Please specify its full path using the environment variable DRMAA_LIBRARY_PATH

# Indeed in git-gat it is specified.

# Change this parameter + other updates
ansible-galaxy install -p roles/ --force -r requirements.yml 

# When it failed (20240926):
# changed: [galaxyduboule.epfl.ch] => 
#   msg: Galaxy version changed from 'a5da8acfc581c77de8d5c5b460ee8e433c295c6e' to 'd914cac22f8fb086f07b5a667cf770b3ac2cba54'

# TASK [galaxyproject.galaxy : Upgrade Galaxy DB] **************************************************************************************************************************************
# fatal: [galaxyduboule.epfl.ch]: FAILED! => changed=true 
#   cmd:
#   - /data/galaxy/galaxy/venv/bin/python
#   - /data/galaxy/galaxy/server/scripts/manage_db.py
#   - -c
#   - /data/galaxy/galaxy/config/galaxy.yml
#   - upgrade
#   delta: '0:00:10.522205'
#   end: '2024-09-26 16:05:51.078271'
#   msg: non-zero return code
#   rc: 1
#   start: '2024-09-26 16:05:40.556066'
#   stderr: |-
#     INFO:alembic.runtime.migration:Context impl PostgresqlImpl.
#     INFO:alembic.runtime.migration:Will assume transactional DDL.
#     INFO:alembic.runtime.migration:Running upgrade c63848676caf -> 04288b6a5b25, make dataset uuids unique
#     Traceback (most recent call last):
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 1967, in _exec_single_context
#         self.dialect.do_execute(
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/default.py", line 924, in do_execute
#         cursor.execute(statement, parameters)
#     psycopg2.errors.UndefinedFunction: function gen_random_uuid() does not exist
#     LINE 3:         SET uuid=REPLACE(gen_random_uuid()::text, '-', '')
#                                      ^
#     HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
  
  
#     The above exception was the direct cause of the following exception:
  
#     Traceback (most recent call last):
#       File "/data/galaxy/galaxy/server/scripts/manage_db.py", line 48, in <module>
#         run()
#       File "/data/galaxy/galaxy/server/scripts/manage_db.py", line 31, in run
#         result = lmdb.run_upgrade()
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/scripts.py", line 182, in run_upgrade
#         self._upgrade(gxy_db_url, GXY)
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/scripts.py", line 202, in _upgrade
#         am.upgrade(model)
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/__init__.py", line 79, in upgrade
#         command.upgrade(self.alembic_cfg, revision)
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/alembic/command.py", line 403, in upgrade
#         script.run_env()
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/alembic/script/base.py", line 583, in run_env
#         util.load_python_file(self.dir, "env.py")
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/alembic/util/pyfiles.py", line 95, in load_python_file
#         module = load_module_py(module_id, path)
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/alembic/util/pyfiles.py", line 113, in load_module_py
#         spec.loader.exec_module(module)  # type: ignore
#       File "<frozen importlib._bootstrap_external>", line 848, in exec_module
#       File "<frozen importlib._bootstrap>", line 219, in _call_with_frames_removed
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/alembic/env.py", line 146, in <module>
#         run_migrations_online()
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/alembic/env.py", line 40, in run_migrations_online
#         _configure_and_run_migrations_online(url)
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/alembic/env.py", line 123, in _configure_and_run_migrations_online
#         context.run_migrations()
#       File "<string>", line 8, in run_migrations
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/alembic/runtime/environment.py", line 948, in run_migrations
#         self.get_context().run_migrations(**kw)
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/alembic/runtime/migration.py", line 627, in run_migrations
#         step.migration_fn(**kw)
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/alembic/versions_gxy/04288b6a5b25_make_dataset_uuids_unique.py", line 70, in upgrade
#         _randomize_uuids_for_purged_datasets_with_duplicated_uuids(connection)
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/migrations/alembic/versions_gxy/04288b6a5b25_make_dataset_uuids_unique.py", line 225, in _randomize_uuids_for_purged_datasets_with_duplicated_uuids
#         connection.execute(updated_purged_uuids)
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 1418, in execute
#         return meth(
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/sql/elements.py", line 515, in _execute_on_connection
#         return connection._execute_clauseelement(
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 1640, in _execute_clauseelement
#         ret = self._execute_context(
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 1846, in _execute_context
#         return self._exec_single_context(
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 1986, in _exec_single_context
#         self._handle_dbapi_exception(
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 2353, in _handle_dbapi_exception
#         raise sqlalchemy_exception.with_traceback(exc_info[2]) from e
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/base.py", line 1967, in _exec_single_context
#         self.dialect.do_execute(
#       File "/data/galaxy/galaxy/venv/lib/python3.8/site-packages/sqlalchemy/engine/default.py", line 924, in do_execute
#         cursor.execute(statement, parameters)
#     sqlalchemy.exc.ProgrammingError: (psycopg2.errors.UndefinedFunction) function gen_random_uuid() does not exist
#     LINE 3:         SET uuid=REPLACE(gen_random_uuid()::text, '-', '')
#                                      ^
#     HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
  
#     [SQL:
#             UPDATE dataset
#             SET uuid=REPLACE(gen_random_uuid()::text, '-', '')
#             WHERE uuid IN (SELECT uuid FROM temp_duplicate_datasets_purged) AND purged = true
#             ]
#     (Background on this error at: https://sqlalche.me/e/20/f405)
#   stderr_lines: <omitted>
#   stdout: ''
#   stdout_lines: <omitted>

# Found on galaxyproject/admins that other people already reported this.
sudo su - postgres
psql -d galaxy
CREATE EXTENSION pgcrypto;

# TASK [galaxyproject.proftpd : Set OS-specific variables]
# ERROR! [DEPRECATED]: ansible.builtin.include has been removed. Use include_tasks or import_tasks instead. This feature was removed from ansible-core in a release after 2023-05-16. Please update your playbooks.

# I remove this role

# Get the list of all installed tools
apikey=$(head -n 1 ~/switchdrive/galaxy.txt)
# Create the list of installed tools
get-tool-list -g galaxyduboule.epfl.ch -a $apikey -o tools/installed_tools.yml --get-all-tools
