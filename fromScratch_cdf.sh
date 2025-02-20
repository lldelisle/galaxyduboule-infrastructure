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
