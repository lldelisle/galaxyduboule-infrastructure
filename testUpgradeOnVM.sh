#!/usr/bin/bash

# I make all the changes in the playbook to change galaxyduboule.epfl.ch to galaxyduboule-test.epfl.ch

# You also need to change your postgresql_backup_dir
# So it will not erase your backup

port=22
guest=galaxyduboule-test.epfl.ch
username=ldelisle

# From the host copy the ssh key:
ssh-copy-id -p ${port} ${username}@${guest}

# ssh on the machine
ssh -p ${port} ${username}@${guest}
# Copy the ssh to helvetios:
ssh-keygen 
ssh-copy-id helvetios.epfl.ch
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
apt-get update
# Upgrade
apt-get upgrade
# Restart
reboot now
# This disconnect you

# Get the last version of the DB:
mkdir /tmp/backup/
scp -r helvetios.epfl.ch:/work/updub/backups_galaxyDB/current /tmp/backup/
# Give access to postgres
chmod 777 -R /tmp/backup/

## Start ansible:

# I think that first you need to put slurm:
ansible-playbook slurm.yml -K
# If you need to upload a postgres db
# First install prostgres
ansible-playbook postgres_only.yml -K

# Ssh:
ssh -p $port ${username}@${guest}
# I try to follow https://github.com/galaxyproject/ansible-postgresql/pull/30#issuecomment-963600656
# Stop the server
systemctl stop postgresql
sudo systemctl status postgresql
# ● postgresql.service - PostgreSQL RDBMS
#      Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
#      Active: inactive (dead) since Fri 2022-12-02 20:36:42 CET; 10s ago
#     Process: 63683 ExecReload=/bin/true (code=exited, status=0/SUCCESS)
#    Main PID: 62043 (code=exited, status=0/SUCCESS)

# Dec 02 10:07:21 svvm0147 systemd[1]: Starting PostgreSQL RDBMS...
# Dec 02 10:07:21 svvm0147 systemd[1]: Finished PostgreSQL RDBMS.
# Dec 02 10:08:03 svvm0147 systemd[1]: Reloading PostgreSQL RDBMS.
# Dec 02 10:08:03 svvm0147 systemd[1]: Reloaded PostgreSQL RDBMS.
# Dec 02 20:36:42 svvm0147 systemd[1]: postgresql.service: Succeeded.
# Dec 02 20:36:42 svvm0147 systemd[1]: Stopped PostgreSQL RDBMS.

# Restore
# Become postgres
sudo su - postgres
# Remove files:
mkdir /tmp/test/
mv /var/lib/postgresql/12/main/* /tmp/test/
# Add backup
rsync -av /tmp/backup/current/ /var/lib/postgresql/12/main
# Add the restore_command:
vim ./12/main/postgresql.auto.conf
# restore_command = 'cp "/tmp/backup/current/wal/%f" "%p"'
# Touch a recovery file
touch /var/lib/postgresql/12/main/recovery.signal

# As $username (with sudo right)
sudo systemctl restart postgresql
sudo systemctl status postgresql
# ● postgresql.service - PostgreSQL RDBMS
#      Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
#      Active: active (exited) since Fri 2022-12-02 20:46:37 CET; 3s ago
#     Process: 89096 ExecStart=/bin/true (code=exited, status=0/SUCCESS)
#    Main PID: 89096 (code=exited, status=0/SUCCESS)

# Dec 02 20:46:37 svvm0147 systemd[1]: Starting PostgreSQL RDBMS...
# Dec 02 20:46:37 svvm0147 systemd[1]: Finished PostgreSQL RDBMS.

# Something went wrong, check the log:
sudo cat /var/log/postgresql/postgresql-12-main.log
# 2022-12-02 20:46:37.204 CET [89095] FATAL:  data directory "/var/lib/postgresql/12/main" has invalid permissions
# 2022-12-02 20:46:37.204 CET [89095] DETAIL:  Permissions should be u=rwx (0700) or u=rwx,g=rx (0750).
# pg_ctl: could not start server
# When I solved permissions I got:
# 2022-12-02 21:10:25.953 CET [90236] FATAL:  required WAL directory "pg_wal" does not exist
# I created the directory
# Then I got:
# cp: cannot stat '/tmp/backup/wal_archive/00000002.history': No such file or directory
# Then I corrected the conf
# Then I got:
# 2022-12-02 21:15:14.469 CET [90603] postgres@template1 FATAL:  database locale is incompatible with operating system
# 2022-12-02 21:15:14.469 CET [90603] postgres@template1 DETAIL:  The database was initialized with LC_COLLATE "en_US.UTF-8",  which is not recognized by setlocale().
# Indeed my locale was 
# locale
# LANG=C.UTF-8
# LANGUAGE=
# LC_CTYPE="C.UTF-8"
# LC_NUMERIC="C.UTF-8"
# LC_TIME="C.UTF-8"
# LC_COLLATE="C.UTF-8"
# LC_MONETARY="C.UTF-8"
# LC_MESSAGES="C.UTF-8"
# LC_PAPER="C.UTF-8"
# LC_NAME="C.UTF-8"
# LC_ADDRESS="C.UTF-8"
# LC_TELEPHONE="C.UTF-8"
# LC_MEASUREMENT="C.UTF-8"
# LC_IDENTIFICATION="C.UTF-8"
# LC_ALL=
# To get en_US.UTF-8:
# sudo locale-gen en_US.UTF-8
# sudo dpkg-reconfigure locales
# Then it worked

# As postgres user:
# Prepare the backup sync:
ssh -q -t ldelisle@helvetios.epfl.ch "mkdir -p /work/updub/backups_galaxyDB_test/current"
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

# galaxy is not running:
sudo journalctl -fu galaxy
# Dec 02 22:16:35 svvm0147 uwsgi[116528]: PermissionError: [Errno 13] Permission denied: '/data/galaxy/uploads'
sudo chown galaxy:galaxy /data/galaxy/
sudo mkdir /data/galaxy/galaxy/server/database/cache
sudo chown galaxy:galaxy /data/galaxy/galaxy/server/database/cache

# I got some installation issues:
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: WARNING conda.core.package_cache_data:_make_single_record(361): Encountered corrupt package tarball at /data/galaxy/galaxy/var/dependencies/_conda/pkgs/ld_impl_linux-64-2.39-hcc3a1bd_1.conda. Conda has removed it, but you need to re-run conda to download it again.
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: WARNING conda.core.package_cache_data:_make_single_record(361): Encountered corrupt package tarball at /data/galaxy/galaxy/var/dependencies/_conda/pkgs/python-3.10.8-h4a9ceb5_0_cpython.conda. Conda has removed it, but you need to re-run conda to download it again.
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: WARNING conda.core.package_cache_data:_make_single_record(361): Encountered corrupt package tarball at /data/galaxy/galaxy/var/dependencies/_conda/pkgs/python_abi-3.10-3_cp310.conda. Conda has removed it, but you need to re-run conda to download it again.
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: WARNING conda.core.package_cache_data:_make_single_record(361): Encountered corrupt package tarball at /data/galaxy/galaxy/var/dependencies/_conda/pkgs/tzdata-2022g-h191b570_0.conda. Conda has removed it, but you need to re-run conda to download it again.
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: [Errno 13] Permission denied: '/data/galaxy/galaxy/server/.cph_tmpy947te0d'
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: [Errno 13] Permission denied: '/data/galaxy/galaxy/server/.cph_tmp4e_psztm'
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: [Errno 13] Permission denied: '/data/galaxy/galaxy/server/.cph_tmpt_lr84a2'
# Dec 02 23:12:55 svvm0147 uwsgi[153612]: [Errno 13] Permission denied: '/data/galaxy/galaxy/server/.cph_tmpl71th7wn'
