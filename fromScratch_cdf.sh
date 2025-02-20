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
