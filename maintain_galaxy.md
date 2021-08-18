# Here are all the guidelines to maintain galaxy up to date and be able to reinstall it

## Install ephemeris/bioblend

```bash
conda create -n bioblend bioblend ephemeris
```

## Update galaxy tag

When the `galaxy_commit_id` is a branch there are regularly bug fixes in this branch. It can be useful to upgrade galaxy with the last commit of the branch:

```bash
ansible-playbook galaxy.yml -K
```

## Add a new tool

Whatever its origin is, you may want to modify [job_conf.xml.j2](./templates/galaxy/config/job_conf.xml.j2) to destinate it to more cpu or more memory.

### From the toolshed

Update the file [my_tools.xml](./tools/my_tools.yml). If it is a tool which was in the previous instance, you may be interested in copying the lines (except the revision) from [former_list.yml](./tools/former_list.yml).
Then use `shed-tools` from ephemeris:

```bash
conda activate bioblend
# I get the API key
apikey=""
# Install the tool
shed-tools install -g https://galaxyduboule.epfl.ch -a $apikey -t tools/my_tools.yml 
```

If you modified the job_conf file, you need to launch the ansible playbook:

```bash
ansible-playbook galaxy.yml -K
```

### Local tool

Create a new folder in [./files/galaxy/tools/] with the name of your tool. Put the xml and other script in the new directory. Then modify [tool_conf.xml.j2](./templates/galaxy/config/tool_conf.xml.j2) add the tool at the end following the above examples. Modify the [group_var file](./group_vars/galaxyserers.yml) in the section galaxy_local_tools add a new line following the above examples.
Finally run the playbook:

```bash
ansible-playbook galaxy.yml -K
```

## Add a new genome

Modify [genomes.yml](./tools/genomes.yml) to add your new genome. Be aware that if the source is ucsc, you need to put the same value in id and dbkey. If it is a custom genome, put the fasta [here](s3://11705-388fd8245175782087c769d3c1f8dabd/custom_genomes/).

Download the shed_data_manager_conf.xml from the server:

```bash
# From the server:
sudo cp /data/galaxy/galaxy/var/config/shed_data_manager_conf.xml /tmp/
sudo chmod 777 /tmp/shed_data_manager_conf.xml 
# Locally:
scp -P $port ${username}@${guest}:/tmp/shed_data_manager_conf.xml tools/
```

Then create the fetch.yml:

```bash
python tools/make_fetch.py -g tools/genomes.yml -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -o tools/fetch.yml
```

Fetch the missing genomes (if you uses a lot of ucsc genome you must rerun it multiple times):

```bash
conda activate bioblend
# I get the API key
apikey=""
run-data-managers --config tools/fetch.yml -g https://galaxyduboule.epfl.ch -a $apikey
```

Then prepare the dm_genomes.yml:

```bash
python tools/fromIDC_Simon/make_dm_genomes.py -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -g tools/genomes.yml -o tools/dm_genomes.yml
```

Build the new entries:

```bash
run-data-managers --config tools/dm_genomes.yml -g https://galaxyduboule.epfl.ch -a $apikey
```

Then update the history:

```bash
python tools/create_History_with_Fasta_Length.py $apikey
```

## Add a new data_manager

Update the file [data_managers_tools.yml](./tools/data_managers_tools.yml).
Then use `shed-tools` from ephemeris:

```bash
conda activate bioblend
# I get the API key
apikey=""
# Install the tool
shed-tools install -g https://galaxyduboule.epfl.ch -a $apikey -t tools/data_managers_tools.yml 
```

Download the shed_data_manager_conf.xml from the server:

```bash
# From the server:
sudo cp /data/galaxy/galaxy/var/config/shed_data_manager_conf.xml /tmp/
sudo chmod 777 /tmp/shed_data_manager_conf.xml 
# Locally:
scp -P $port ${username}@${guest}:/tmp/shed_data_manager_conf.xml tools/
```

Then prepare the dm_genomes.yml:

```bash
python tools/make_dm_genomes_more_params.py -d tools/data_managers_tools.yml -x tools/shed_data_manager_conf.xml -g tools/genomes.yml -o tools/dm_genomes.yml
```

Build the new entries:

```bash
python tools/run_dm_with_params.py  --config tools/dm_genomes.yml  -g https://galaxyduboule.epfl.ch -a $apikey
# Before homer I was doing:
# run-data-managers --config tools/dm_genomes.yml -g https://galaxyduboule.epfl.ch -a $apikey
```

## Add a new useful dataset

Locally, add it to [./useful_datasets]. URL add it to [create_History_with_UsefulFiles.py](./tools/create_History_with_UsefulFiles.py). Big file, add it to the s3 server [here](s3://11705-388fd8245175782087c769d3c1f8dabd/useful_datasets/).
Then run the python script:

```bash
conda activate bioblend
# I get the API key
apikey=""
# Create the history
python tools/create_History_with_UsefulFiles.py $apikey
```
