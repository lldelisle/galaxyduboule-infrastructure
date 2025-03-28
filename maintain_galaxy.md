# Here are all the guidelines to maintain galaxy up to date and be able to reinstall it

## Install ephemeris/bioblend

```bash
conda create -n lastVersion bioblend ephemeris
# Or
conda activate lastVersion
conda install bioblend ephemeris
# Or
python3 -m venv ~/galaxy_venv
. ~/galaxy_venv/bin/activate
pip install bioblend ephemeris
pip install setuptools
```

## Update galaxy tag

When the `galaxy_commit_id` is a branch there are regularly bug fixes in this branch. It can be useful to upgrade galaxy with the last commit of the branch:

```bash
ansible-playbook galaxy.yml -K
```

## Add a new tool

Whatever its origin is, you may want to modify the `galaxy_job_config` in [galaxyservers.yml](./group_vars/galaxyservers.yml) to destinate it to more cpu or more memory.

### From the toolshed

#### New tool

Update the file [my_tools.xml](./tools/my_tools.yml). To decide the `tool_panel_section_label`, you can use what is [here](https://training.galaxyproject.org/training-material/api/toolcats.json).

Then update the .lock:

```
python3 tools/fix-lockfile.py tools/my_tools.yml
```

Then do the same steps as if you wanted to update.

#### Update currently installed tools

```bash
conda activate lastVersion
# Or
python -m venv ~/galaxy_venv
python3 tools/update-tool.py tools/my_tools.yml
```

Then use `shed-tools` from ephemeris:

```bash
conda activate lastVersion
# Or
python -m venv ~/galaxy_venv
# I get the API key
apikey=$(head -n 1 ~/switchdrive/galaxy.txt)
# Install the tool
shed-tools install -g http://galaxyduboule.college-de-france.fr -a $apikey -t tools/my_tools.yml.lock
```

If you modified the `galaxy_job_config` file, you need to launch the ansible playbook:

```bash
ansible-playbook galaxy.yml -K
```

### Local tool

Create a new folder in [./files/galaxy/tools/] with the name of your tool. Put the xml and other script in the new directory. Then modify [tool_conf.xml.j2](./templates/galaxy/config/tool_conf.xml.j2) add the tool at the end following the above examples. Modify the [group_var file](./group_vars/galaxyservers.yml) in the section galaxy_local_tools add a new line following the above examples.
Finally run the playbook:

```bash
ansible-playbook galaxy.yml -K
```

## Add a new genome

Modify [genomes.yml](./tools/genomes.yml) to add your new genome. It the genome is a specific version of a specific species which is not available in galaxy. Please write an issue to [IDC](https://github/galaxyproject/idc). If it is a custom genome, put the fasta on the NAS in `lab.data/archive/perso_storage/custom_genomes`.

Download the shed_data_manager_conf.xml from the server:

```bash
# From the server:
sudo cp /data/galaxy/galaxy/var/config/shed_data_manager_conf.xml /tmp/
sudo chmod 777 /tmp/shed_data_manager_conf.xml 
# Locally:
port=22
guest=192.168.202.69
username=lldelisle
scp -P $port ${username}@${guest}:/tmp/shed_data_manager_conf.xml tools/
```

Then create the fetch.yml:

```bash
conda activate lastVersion
# Or
python -m venv ~/galaxy_venv
python tools/make_fetch.py -g tools/genomes.yml -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -o tools/fetch.yml
```

Fetch the missing genomes (if you uses a lot of ucsc genome you must rerun it multiple times):

```bash
conda activate lastVersion
# Or
python -m venv ~/galaxy_venv
# I get the API key
apikey=$(head -n 1 ~/switchdrive/galaxy.txt)
run-data-managers --config tools/fetch.yml -g http://galaxyduboule.college-de-france.fr -a $apikey
```

Then prepare the dm_genomes.yml:

```bash
python tools/make_dm_genomes_more_params.py -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -g tools/genomes.yml -o tools/dm_genomes.yml
# Before homer I was doing:
# python tools/fromIDC_Simon/make_dm_genomes.py -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -g tools/genomes.yml -o tools/dm_genomes.yml
```

Remove duplicated DM.

Build the new entries:

```bash
python tools/run_dm_with_params.py  --config tools/dm_genomes.yml  -g http://galaxyduboule.college-de-france.fr -a $apikey
# Before homer I was doing:
# run-data-managers --config tools/dm_genomes.yml -g http://galaxyduboule.college-de-france.fr -a $apikey
```

Then update the history:

```bash
python tools/create_History_with_Fasta_Length.py $apikey
```

## Add a new data_manager

Update the file [data_managers_tools.yml](./tools/data_managers_tools.yml).

Then update the .lock:

```
python3 tools/fix-lockfile.py tools/data_managers_tools.yml
python3 tools/update-tool.py tools/data_managers_tools.yml
```

Then use `shed-tools` from ephemeris to install it:

```bash
conda activate lastVersion
# Or
. ~/galaxy_venv/bin/activate
# I get the API key
apikey=$(head -n 1 ~/switchdrive/galaxy.txt)
# Install the tool
shed-tools install -g http://galaxyduboule.college-de-france.fr -a $apikey -t tools/data_managers_tools.yml.lock
```

Find the table entry:
```bash
manager=data_manager_bwa_mem_index_builder
cat /data/galaxy/galaxy/var/shed_tools/toolshed.g2.bx.psu.edu/repos/*/$manager/*/$manager/tool_data_table_conf.xml.sample
```

Copy the table entry [here](./files/galaxy/config/tool_data_table_conf.xml) but remove the `tool-data/` in the path of the loc file.

Run the ansible playbook:

```bash
ansible-playbook galaxy.yml -K
```

If not done automatically restart galaxy (from the server):

```bash
sudo galaxyctl restart
```

Download the shed_data_manager_conf.xml from the server:

```bash
# From the server:
sudo cp /data/galaxy/galaxy/var/config/shed_data_manager_conf.xml /tmp/
sudo chmod 777 /tmp/shed_data_manager_conf.xml 
# Locally:
port=22
guest=192.168.202.69
username=lldelisle
scp -P $port ${username}@${guest}:/tmp/shed_data_manager_conf.xml tools/
```

Then prepare the dm_genomes.yml:

```bash
python tools/make_dm_genomes_more_params.py -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -g tools/genomes.yml -o tools/dm_genomes.yml
```

Remove duplicated DM.

Build the new entries:

```bash
python tools/run_dm_with_params.py  --config tools/dm_genomes.yml  -g http://galaxyduboule.college-de-france.fr -a $apikey
# Before homer I was doing:
# run-data-managers --config tools/dm_genomes.yml -g http://galaxyduboule.college-de-france.fr -a $apikey
```

## Add a new useful dataset

Locally, add it to [./useful_datasets]. URL add it to [create_History_with_UsefulFiles.py](./tools/create_History_with_UsefulFiles.py). Big file, add it to the s3 server [here](s3://11705-388fd8245175782087c769d3c1f8dabd/useful_datasets/).
Then run the python script:

```bash
conda activate lastVersion
# I get the API key
apikey=$(head -n 1 ~/switchdrive/galaxy.txt)
# Create the history
python tools/create_History_with_UsefulFiles.py $apikey
```

## Backup the list of installed tools

```bash
conda activate lastVersion
# I get the API key
apikey=$(head -n 1 ~/switchdrive/galaxy.txt)
# Create the list of installed tools
get-tool-list -g galaxyduboule.epfl.ch -a $apikey -o tools/installed_tools.yml --get-all-tools
```