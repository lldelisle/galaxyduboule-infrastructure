port=2222
guest=localhost
username=lldelisle

# ssh on the machine

ssh -p ${port} ${username}@${guest}
# become root:
sudo su -
# Put the password
# Create the folder for postgresql
mkdir -p /data/postgresql
ln -s /data/postgresql /var/lib/postgresql
# Update the databases
apt-get update
# Check what is upgradable
apt-get upgrade --dry-run
# Upgrade
apt-get dist-upgrade
# Reboot
reboot now
# Remove unneeded packages
apt autoremove

## Start ansible:

# Install dependencies (use --force if you updated it);
ansible-galaxy install -p roles/ --force -r requirements.yml

# I think that first you need to put slurm:
ansible-playbook slurm.yml -K

# TASK [galaxyproject.repos : Add slurm-drmaa PPA (Ubuntu)] ***********************************************************************************************************************************************************************************************************
# [WARNING]: Module remote_tmp /root/.ansible/tmp did not exist and was created with a mode of 0700, this may cause issues when running as another user. To avoid this, create the remote_tmp dir with the correct permissions manually
# [WARNING]: Failed to update cache after 1 due to E:The repository 'https://ppa.launchpadcontent.net/natefoo/slurm-drmaa/ubuntu noble Release' does not have a Release file. retry, retrying
# [WARNING]: Sleeping for 1 seconds, before attempting to update the cache again
# [WARNING]: Failed to update cache after 2 due to W:Updating from such a repository can't be done securely, and is therefore disabled by default., W:See apt-secure(8) manpage for repository creation and user configuration details., E:The repository
# 'https://ppa.launchpadcontent.net/natefoo/slurm-drmaa/ubuntu noble Release' does not have a Release file. retry, retrying
# [WARNING]: Sleeping for 2 seconds, before attempting to update the cache again
# [WARNING]: Failed to update cache after 3 due to W:Updating from such a repository can't be done securely, and is therefore disabled by default., W:See apt-secure(8) manpage for repository creation and user configuration details., E:The repository
# 'https://ppa.launchpadcontent.net/natefoo/slurm-drmaa/ubuntu noble Release' does not have a Release file. retry, retrying
# [WARNING]: Sleeping for 4 seconds, before attempting to update the cache again
# [WARNING]: Failed to update cache after 4 due to W:Updating from such a repository can't be done securely, and is therefore disabled by default., W:See apt-secure(8) manpage for repository creation and user configuration details., E:The repository
# 'https://ppa.launchpadcontent.net/natefoo/slurm-drmaa/ubuntu noble Release' does not have a Release file. retry, retrying
# [WARNING]: Sleeping for 8 seconds, before attempting to update the cache again
# [WARNING]: Failed to update cache after 5 due to W:Updating from such a repository can't be done securely, and is therefore disabled by default., W:See apt-secure(8) manpage for repository creation and user configuration details., E:The repository
# 'https://ppa.launchpadcontent.net/natefoo/slurm-drmaa/ubuntu noble Release' does not have a Release file. retry, retrying
# [WARNING]: Sleeping for 12 seconds, before attempting to update the cache again
# fatal: [galaxyduboule.college-de-france.fr]: FAILED! => changed=false 
#   msg: 'Failed to update apt cache after 5 retries: W:Updating from such a repository can''t be done securely, and is therefore disabled by default., W:See apt-secure(8) manpage for repository creation and user configuration details., E:The repository ''https://ppa.launchpadcontent.net/natefoo/slurm-drmaa/ubuntu noble Release'' does not have a Release file.'

# PLAY RECAP **********************************************************************************************************************************************************************************************************************************************************
# galaxyduboule.college-de-france.fr : ok=1    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0   

# Remove the repos and rerun
ansible-playbook slurm.yml -K
# TASK [galaxyproject.slurm : Ensure slurmctld is enabled and running] ************************************************************************************************************************************************************************************************
# fatal: [galaxyduboule.college-de-france.fr]: FAILED! => changed=false 
#   msg: |-
#     Unable to start service slurmctld: Job for slurmctld.service failed because the control process exited with error code.
#     See "systemctl status slurmctld.service" and "journalctl -xeu slurmctld.service" for details.

# PLAY RECAP **********************************************************************************************************************************************************************************************************************************************************
# galaxyduboule.college-de-france.fr : ok=12   changed=3    unreachable=0    failed=1    skipped=14   rescued=0    ignored=0   

# On the machine:
systemctl status slurmctld.service
# root@workstationduboule:~# systemctl status slurmctld.service
# × slurmctld.service - Slurm controller daemon
#      Loaded: loaded (/usr/lib/systemd/system/slurmctld.service; enabled; preset: enabled)
#      Active: failed (Result: exit-code) since Thu 2025-02-20 18:12:48 CET; 1min 42s ago
#        Docs: man:slurmctld(8)
#     Process: 7683 ExecStart=/usr/sbin/slurmctld --systemd $SLURMCTLD_OPTIONS (code=exited, status=1/FAILURE)
#    Main PID: 7683 (code=exited, status=1/FAILURE)
#         CPU: 9ms

# Feb 20 18:12:48 workstationduboule systemd[1]: Starting slurmctld.service - Slurm controller daemon...
# Feb 20 18:12:48 workstationduboule (lurmctld)[7683]: slurmctld.service: Referenced but unset environment variable evaluates to an empty string: SLURMCTLD_OPTIONS
# Feb 20 18:12:48 workstationduboule slurmctld[7683]: slurmctld: error: Configured MailProg is invalid
# Feb 20 18:12:48 workstationduboule slurmctld[7683]: slurmctld: slurmctld version 23.11.4 started on cluster cluster
# Feb 20 18:12:48 workstationduboule slurmctld[7683]: slurmctld: fatal: Can't find plugin for select/cons_res
# Feb 20 18:12:48 workstationduboule systemd[1]: slurmctld.service: Main process exited, code=exited, status=1/FAILURE
# Feb 20 18:12:48 workstationduboule systemd[1]: slurmctld.service: Failed with result 'exit-code'.
# Feb 20 18:12:48 workstationduboule systemd[1]: Failed to start slurmctld.service - Slurm controller daemon.

# To solve 'Configured MailProg is invalid'
apt-get -y install mailutils
# I chose 'No configuration' because I have no idea of a SMTP I could use
systemctl restart slurmctld.service
# root@workstationduboule:~# systemctl restart slurmctld.service
# Job for slurmctld.service failed because the control process exited with error code.
# See "systemctl status slurmctld.service" and "journalctl -xeu slurmctld.service" for details.
# root@workstationduboule:~# systemctl status slurmctld.service
# × slurmctld.service - Slurm controller daemon
#      Loaded: loaded (/usr/lib/systemd/system/slurmctld.service; enabled; preset: enabled)
#      Active: failed (Result: exit-code) since Thu 2025-02-20 21:13:33 CET; 12s ago
#        Docs: man:slurmctld(8)
#     Process: 8604 ExecStart=/usr/sbin/slurmctld --systemd $SLURMCTLD_OPTIONS (code=exited, status=1/FAILURE)
#    Main PID: 8604 (code=exited, status=1/FAILURE)
#         CPU: 11ms

# Feb 20 21:13:32 workstationduboule systemd[1]: Starting slurmctld.service - Slurm controller daemon...
# Feb 20 21:13:33 workstationduboule (lurmctld)[8604]: slurmctld.service: Referenced but unset environment variable evaluates to an empty string: SLURMCTLD_OPTIONS
# Feb 20 21:13:33 workstationduboule slurmctld[8604]: slurmctld: slurmctld version 23.11.4 started on cluster cluster
# Feb 20 21:13:33 workstationduboule slurmctld[8604]: slurmctld: fatal: Can't find plugin for select/cons_res
# Feb 20 21:13:33 workstationduboule systemd[1]: slurmctld.service: Main process exited, code=exited, status=1/FAILURE
# Feb 20 21:13:33 workstationduboule systemd[1]: slurmctld.service: Failed with result 'exit-code'.
# Feb 20 21:13:33 workstationduboule systemd[1]: Failed to start slurmctld.service - Slurm controller daemon.

# I try to reboot in case it helps...
reboot now

# lldelisle@workstationduboule:~$ systemctl status slurmctld.service
# × slurmctld.service - Slurm controller daemon
#      Loaded: loaded (/usr/lib/systemd/system/slurmctld.service; enabled; preset: enabled)
#      Active: failed (Result: exit-code) since Thu 2025-02-20 21:30:29 CET; 4min 16s ago
#        Docs: man:slurmctld(8)
#     Process: 2298 ExecStart=/usr/sbin/slurmctld --systemd $SLURMCTLD_OPTIONS (code=exited, status=1/FAILURE)
#    Main PID: 2298 (code=exited, status=1/FAILURE)
#         CPU: 9ms

# Feb 20 21:30:29 workstationduboule systemd[1]: Starting slurmctld.service - Slurm controller daemon...
# Feb 20 21:30:29 workstationduboule (lurmctld)[2298]: slurmctld.service: Referenced but unset environment variable evaluates to an empty string: SLURMCTLD_OPTIONS
# Feb 20 21:30:29 workstationduboule slurmctld[2298]: slurmctld: slurmctld version 23.11.4 started on cluster cluster
# Feb 20 21:30:29 workstationduboule slurmctld[2298]: slurmctld: fatal: Can't find plugin for select/cons_res
# Feb 20 21:30:29 workstationduboule systemd[1]: slurmctld.service: Main process exited, code=exited, status=1/FAILURE
# Feb 20 21:30:29 workstationduboule systemd[1]: slurmctld.service: Failed with result 'exit-code'.
# Feb 20 21:30:29 workstationduboule systemd[1]: Failed to start slurmctld.service - Slurm controller daemon.

# I try to install slurm
apt-get install slurm
# Nothing changes
apt-get --purge remove slurm

# There is the so: /usr/lib/x86_64-linux-gnu/slurm-wlm/select_cons_tres.so

# I comment the line in the config,
# Rerun the playbook everything works
systemctl status slurmctld.service
# ● slurmctld.service - Slurm controller daemon
#      Loaded: loaded (/usr/lib/systemd/system/slurmctld.service; enabled; preset: enabled)
#      Active: active (running) since Thu 2025-02-20 22:36:32 CET; 32s ago
#        Docs: man:slurmctld(8)
#    Main PID: 5349 (slurmctld)
#       Tasks: 13
#      Memory: 2.4M (peak: 3.6M)
#         CPU: 62ms
#      CGroup: /system.slice/slurmctld.service
#              ├─5349 /usr/sbin/slurmctld --systemd
#              └─5350 "slurmctld: slurmscriptd"

# Feb 20 22:36:32 workstationduboule systemd[1]: Started slurmctld.service - Slurm controller daemon.
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: No memory enforcing mechanism configured.
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: Recovered state of 1 nodes
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: Recovered information about 0 jobs
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: select/cons_tres: part_data_create_array: select/cons_tres: preparing for 1 partitions
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: Recovered state of 0 reservations
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: read_slurm_conf: backup_controller not specified
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: select/cons_tres: select_p_reconfigure: select/cons_tres: reconfigure
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: select/cons_tres: part_data_create_array: select/cons_tres: preparing for 1 partitions
# Feb 20 22:36:32 workstationduboule slurmctld[5349]: slurmctld: Running as primary controller

# I reset the SelectType I want and add SlurmctldDebug: debug5.
# In the journalctl I could find:

# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: Trying to load plugin /usr/lib/x86_64-linux-gnu/slurm-wlm/select_linear.so
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: plugin_load_from_file->_verify_syms: found Slurm plugin name:Linear node selection plugin type:select/linear version:0x170b04
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: select/linear: init: Linear node selection plugin loaded with argument 17
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: Success.
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: Trying to load plugin /usr/lib/x86_64-linux-gnu/slurm-wlm/select_cons_tres.so
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: plugin_load_from_file->_verify_syms: found Slurm plugin name:Trackable RESources (TRES) Selection plugin type:select/cons_tres version:0x170b04
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: select/cons_tres: init: select/cons_tres loaded
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: Success.
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: Trying to load plugin /usr/lib/x86_64-linux-gnu/slurm-wlm/select_cray_aries.so
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: plugin_load_from_file->_verify_syms: found Slurm plugin name:Cray/Aries node selection plugin type:select/cray_aries version:0x170b04
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: select/cray_aries: init: Cray/Aries node selection plugin loaded
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: debug3: Success.
# Feb 20 22:49:03 workstationduboule slurmctld[5835]: slurmctld: fatal: Can't find plugin for select/cons_res

# I remove the SelectType and relaunch the ansible and everything is fine:

# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Trying to load plugin /usr/lib/x86_64-linux-gnu/slurm-wlm/select_linear.so
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: plugin_load_from_file->_verify_syms: found Slurm plugin name:Linear node selection plugin type:select/linear version:0x170b04
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: select/linear: init: Linear node selection plugin loaded with argument 17
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Success.
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Trying to load plugin /usr/lib/x86_64-linux-gnu/slurm-wlm/select_cons_tres.so
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: plugin_load_from_file->_verify_syms: found Slurm plugin name:Trackable RESources (TRES) Selection plugin type:select/cons_tres version:0x170b04
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: select/cons_tres: init: select/cons_tres loaded
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Success.
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Trying to load plugin /usr/lib/x86_64-linux-gnu/slurm-wlm/select_cray_aries.so
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: plugin_load_from_file->_verify_syms: found Slurm plugin name:Cray/Aries node selection plugin type:select/cray_aries version:0x170b04
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: select/cray_aries: init: Cray/Aries node selection plugin loaded
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Success.
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug2: No acct_gather.conf file (/etc/slurm/acct_gather.conf)
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Trying to load plugin /usr/lib/x86_64-linux-gnu/slurm-wlm/prep_script.so
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: plugin_load_from_file->_verify_syms: found Slurm plugin name:Script PrEp plugin type:prep/script version:0x170b04
# Feb 20 22:54:56 workstationduboule slurmctld[6182]: slurmctld: debug3: Success.

# The value was 'cons_tres' and not 'cons_res' like in old versions.

# If you need to upload a postgres db
# First install prostgres
ansible-playbook postgres_only.yml -K


# Ssh:
ssh -p $port ${username}@${guest}
# I try to follow https://github.com/galaxyproject/ansible-postgresql/pull/30#issuecomment-963600656
# Stop the server
sudo su -
systemctl stop postgresql
systemctl status postgresql
# ○ postgresql.service - PostgreSQL RDBMS
#      Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; preset: enabled)
#      Active: inactive (dead) since Thu 2025-02-20 23:15:29 CET; 14s ago
#    Duration: 2min 39.407s
#     Process: 10158 ExecReload=/bin/true (code=exited, status=0/SUCCESS)
#    Main PID: 8363 (code=exited, status=0/SUCCESS)
#         CPU: 2ms

# Feb 20 23:12:50 workstationduboule systemd[1]: Starting postgresql.service - PostgreSQL RDBMS...
# Feb 20 23:12:50 workstationduboule systemd[1]: Finished postgresql.service - PostgreSQL RDBMS.
# Feb 20 23:13:20 workstationduboule systemd[1]: Reloading postgresql.service - PostgreSQL RDBMS...
# Feb 20 23:13:20 workstationduboule systemd[1]: Reloaded postgresql.service - PostgreSQL RDBMS.
# Feb 20 23:15:29 workstationduboule systemd[1]: postgresql.service: Deactivated successfully.
# Feb 20 23:15:29 workstationduboule systemd[1]: Stopped postgresql.service - PostgreSQL RDBMS.

# Restore
# Become postgres
su - postgres
# The current version of postgresql is 16
# Let see if it wors:
# Remove files:
mkdir /tmp/test/
mv /var/lib/postgresql/16/main/* /tmp/test/
# Add backup
rsync -av /data/nas/lab.data/archive/backups_galaxyDB20250220T080650Z/20250220T080650Z/ /var/lib/postgresql/16/main
# Add the restore_command:
vim ./16/main/postgresql.auto.conf
# restore_command = 'cp "/data/nas/lab.data/archive/backups_galaxyDB20250220T080650Z/20250220T080650Z/wal/%f" "%p"'
# Touch a recovery file
touch /var/lib/postgresql/16/main/recovery.signal

# As $username (with sudo right)
sudo systemctl restart postgresql
sudo systemctl status postgresql
# ● postgresql.service - PostgreSQL RDBMS
#      Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; preset: enabled)
#      Active: active (exited) since Thu 2025-02-20 23:24:42 CET; 39s ago
#     Process: 10694 ExecStart=/bin/true (code=exited, status=0/SUCCESS)
#    Main PID: 10694 (code=exited, status=0/SUCCESS)
#         CPU: 2ms

# Feb 20 23:24:42 workstationduboule systemd[1]: Starting postgresql.service - PostgreSQL RDBMS...
# Feb 20 23:24:42 workstationduboule systemd[1]: Finished postgresql.service - PostgreSQL RDBMS.

# Something went wrong, check the log:
sudo cat /var/log/postgresql/postgresql-16-main.log
# 2025-02-20 23:24:41.963 CET [10692] FATAL:  data directory "/var/lib/postgresql/16/main" has invalid permissions
# 2025-02-20 23:24:41.963 CET [10692] DETAIL:  Permissions should be u=rwx (0700) or u=rwx,g=rx (0750).
chmod 0700 16/main/

# 2025-02-20 23:29:36.720 CET [10780] FATAL:  database files are incompatible with server
# 2025-02-20 23:29:36.720 CET [10780] DETAIL:  The data directory was initialized by PostgreSQL version 12, which is not compatible with this version 16.6 (Ubuntu 16.6-0ubuntu0.24.04.1).

# Put back what was in main:
rm -r /var/lib/postgresql/16/main/*
mv /tmp/test/* /var/lib/postgresql/16/main/
# Restart
# As $username (with sudo right)
sudo systemctl restart postgresql

# Back to galaxyduboule.epfl.ch
# Export the database with:
# pg_dump -d galaxy -F t -b -f ~/20250220.tar

# Restore
pg_restore --dbname=galaxy --verbose /data/nas/lab.data/archive/backups_galaxyDB/20250220.tar

# Logout as postgres
exit
# Logout
exit

# Then galaxy
ansible-playbook galaxy.yml -K

# Got an error:
# TASK [galaxyproject.galaxy : Get current Galaxy DB version] **********************************************************************************************************************************************************************************************************************
# fatal: [galaxyduboule.college-de-france.fr]: FAILED! => changed=false 
#   cmd:
#   - /data/galaxy/galaxy/venv/bin/python
#   - /data/galaxy/galaxy/server/scripts/manage_db.py
#   - -c
#   - /data/galaxy/galaxy/config/galaxy.yml
#   - db_version
#   delta: '0:00:00.399601'
#   end: '2025-02-21 06:55:41.246020'
#   failed_when_result: true
#   msg: non-zero return code
#   rc: 1
#   start: '2025-02-21 06:55:40.846419'
#   stderr: |-
#     Traceback (most recent call last):
#       File "/data/galaxy/galaxy/server/scripts/manage_db.py", line 12, in <module>
#         from galaxy.model.migrations.scripts import LegacyManageDb
#       File "/data/galaxy/galaxy/server/lib/galaxy/model/__init__.py", line 141, in <module>
#         from galaxy.files.templates import (
#       File "/data/galaxy/galaxy/server/lib/galaxy/files/__init__.py", line 16, in <module>
#         from galaxy.files.sources import (
#       File "/data/galaxy/galaxy/server/lib/galaxy/files/sources/__init__.py", line 37, in <module>
#         from galaxy.util.template import fill_template
#       File "/data/galaxy/galaxy/server/lib/galaxy/util/template.py", line 4, in <module>
#         from lib2to3.refactor import RefactoringTool
#     ModuleNotFoundError: No module named 'lib2to3'
#   stderr_lines: <omitted>
#   stdout: ''
#   stdout_lines: <omitted>

# I try to run the playbook in case one of the dependency was not installed correctly.

# I am installing the library myself:
sudo apt-get install python3-lib2to3

# Now new error about the certificates
# TASK [galaxyproject.nginx : Check SSL nginx config] **********************************************************************************************
# fatal: [galaxyduboule.college-de-france.fr]: FAILED! => changed=false 
#   cmd:
#   - nginx
#   - -t
#   - -c
#   - /etc/nginx/nginx.conf
#   delta: '0:00:00.233247'
#   end: '2025-02-21 08:35:55.062406'
#   msg: non-zero return code
#   rc: 1
#   start: '2025-02-21 08:35:54.829159'
#   stderr: |-
#     2025/02/21 08:35:54 [emerg] 36261#36261: no "ssl_certificate" is defined for the "listen ... ssl" directive in /etc/nginx/sites-enabled/galaxy:14
#     nginx: configuration file /etc/nginx/nginx.conf test failed
#   stderr_lines: <omitted>
#   stdout: ''
#   stdout_lines: <omitted>

# I add the certbot role
ansible-galaxy install -p roles -r requirements.yml

ansible-playbook galaxy.yml -K

# fatal: [galaxyduboule.college-de-france.fr]: FAILED! => changed=true 
#   cmd:
#   - /opt/certbot/bin/certbot
#   - certonly
#   - --test-cert
#   - --non-interactive
#   - --webroot
#   - --register-unsafely-without-email
#   - --agree-tos
#   - -w
#   - /srv/nginx/_well-known_root
#   - -d
#   - galaxyduboule.college-de-france.fr
#   delta: '0:00:02.681775'
#   end: '2025-02-21 08:46:49.762774'
#   msg: non-zero return code
#   rc: 1
#   start: '2025-02-21 08:46:47.080999'
#   stderr: |-
#     Saving debug log to /var/log/letsencrypt/letsencrypt.log
#     Some challenges have failed.
#     Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
#   stderr_lines: <omitted>
#   stdout: |-
#     Account registered.
#     Requesting a certificate for galaxyduboule.college-de-france.fr
  
#     Certbot failed to authenticate some domains (authenticator: webroot). The Certificate Authority reported these problems:
#       Domain: galaxyduboule.college-de-france.fr
#       Type:   dns
#       Detail: DNS problem: NXDOMAIN looking up A for galaxyduboule.college-de-france.fr - check that a DNS record exists for this domain; DNS problem: NXDOMAIN looking up AAAA for galaxyduboule.college-de-france.fr - check that a DNS record exists for this domain
  
#     Hint: The Certificate Authority failed to download the temporary challenge files created by Certbot. Ensure that the listed domains serve their content from the provided --webroot-path/-w and that files created there can be downloaded from the internet.
#   stdout_lines: <omitted>

# I need to change the host name:

# TASK [usegalaxy_eu.certbot : Request certificate] ********************************************************************************************************************************************************************************************************************************
# fatal: [workstationduboule]: FAILED! => changed=true 
#   cmd:
#   - /opt/certbot/bin/certbot
#   - certonly
#   - --test-cert
#   - --non-interactive
#   - --webroot
#   - --register-unsafely-without-email
#   - --agree-tos
#   - -w
#   - /srv/nginx/_well-known_root
#   - -d
#   - workstationduboule
#   delta: '0:00:00.972794'
#   end: '2025-02-21 08:51:29.042367'
#   msg: non-zero return code
#   rc: 1
#   start: '2025-02-21 08:51:28.069573'
#   stderr: |-
#     Saving debug log to /var/log/letsencrypt/letsencrypt.log
#     An unexpected error occurred:
#     Invalid identifiers requested :: Cannot issue for "workstationduboule": Domain name needs at least one dot
#     Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
#   stderr_lines: <omitted>
#   stdout: Requesting a certificate for workstationduboule
#   stdout_lines: <omitted>

# Change the playbook to run without ssl
