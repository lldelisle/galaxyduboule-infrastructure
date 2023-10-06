# Debugging/Tricks examples

## To increase priority of a job

`sudo scontrol update job=4191 Priority=4294967292`

## If the local node is not responding

For example this happened when the server ran out of memory.

`scontrol update nodename=localhost state=idle`

## Give access to the server to an EPFL member

```bash
usermod -a -G galaxyduboule <username>
# Then to create a home directory
sudo su - <username>
```

To remove:

`gpasswd -d <username> galaxyduboule`

## Grafana shows no more data

It was because there was no space left on `/`.

```bash
sudo systemctl status grafana-server.service
sudo systemctl status telegraf.service
sudo systemctl status influxdb.service 
sudo systemctl restart influxdb.service 
```

## Check influxdb

```bash
influx
show databases
use telegraf
show measurements
```

For example, get the last measurements of "user-disk-usage":

```bash
SELECT * FROM "user-disk-usage" ORDER BY time DESC LIMIT 2;
```

To get the time as human readable:

```bash
precision rfc3339
```

## Conda fails to solve environment

This has been solved thanks to @mvdbeek

In my example, a conda process was never ending:

```log
Jul 04 11:25:46 updubsrv1 uwsgi[19861]: Solving environment: ...working...
```

A way to check what is running:

```bash
$ ps -axf| grep conda
19861 ?        Sl     0:28  |   \_ /data/galaxy/galaxy/var/dependencies/_conda/bin/python /data/galaxy/galaxy/var/dependencies/_conda/bin/conda create -y --quiet --override-channels --channel conda-forge --channel bioconda --channel defaults --name mulled-v1-c9f488ec0e9a96bed61dcc2e074b26ce37ed596751861ff368fd824a2a5f11d4 htseq=0.9.1 samtools=1.7
```

I killed the process: ``sudo kill 19861``

Then galaxy is trying to solve each dependency by itself.

Meanwhile, we can create the conda environment:

```bash
sudo su - galaxy
/data/galaxy/galaxy/var/dependencies/_conda/bin/python /data/galaxy/galaxy/var/dependencies/_conda/bin/conda create -y --quiet --override-channels --channel conda-forge --channel bioconda --channel defaults -p /data/galaxy/galaxy/var/dependencies/_conda/envs/mulled-v1-c9f488ec0e9a96bed61dcc2e074b26ce37ed596751861ff368fd824a2a5f11d4 htseq=0.9.1 samtools=1.7 python=3.8
```

I got an error: `samtools: error while loading shared libraries: libcrypto.so.1.0.0: cannot open shared object file: No such file or directory` which is classical with old samtools with new openssl.

Finally @cat-bro gave me the list of the mulled which worked and the solution was:

```bash
/data/galaxy/galaxy/var/dependencies/_conda/bin/python /data/galaxy/galaxy/var/dependencies/_conda/bin/conda create -y --quiet --override-channels --channel conda-forge --channel bioconda --channel defaults -p /data/galaxy/galaxy/var/dependencies/_conda/envs/mulled-v1-c9f488ec0e9a96bed61dcc2e074b26ce37ed596751861ff368fd824a2a5f11d4 htseq=0.9.1 samtools=1.7 python=3.7.1 openssl=1.0.2p
```

### When it is simply too long and would be faster with mamba

```bash
ldelisle@updubsrv1:/data/home/ldelisle$ ps aux | grep conda
galaxy    984736  105  0.1 1051200 564896 ?      R    15:04   0:19 /data/galaxy/galaxy/var/dependencies/_conda/bin/python /data/galaxy/galaxy/var/dependencies/_conda/bin/conda create -y --quiet --override-channels --channel conda-forge --channel bioconda --channel defaults --channel pytorch --channel ilastik-forge --name mulled-v1-2f81e71dc6f04cbc79963dc095824fbd17740893f6238b8659bee0b436f66105 fiji=20220414 python=3.7 fiji-max_inscribed_circles=1.1.2 fiji-ilastik=1.8.2
ldelisle@updubsrv1:/data/home/ldelisle$ sudo kill 984736
ldelisle@updubsrv1:/data/home/ldelisle$ sudo su - galaxy
galaxy@updubsrv1:~$ /data/galaxy/galaxy/var/dependencies/_conda/bin/python /data/galaxy/galaxy/var/dependencies/_conda/bin/conda create -y --quiet --override-channels --channel conda-forge --channel bioconda --channel defaults -p /data/galaxy/galaxy/var/dependencies/_conda/envs/mulled-v1-2f81e71dc6f04cbc79963dc095824fbd17740893f6238b8659bee0b436f66105 python=3.7 mamba
galaxy@updubsrv1:~$ . '/data/galaxy/galaxy/var/dependencies/_conda/bin/activate' /data/galaxy/galaxy/var/dependencies/_conda/envs/mulled-v1-2f81e71dc6f04cbc79963dc095824fbd17740893f6238b8659bee0b436f66105/
(mulled-v1-2f81e71dc6f04cbc79963dc095824fbd17740893f6238b8659bee0b436f66105) galaxy@updubsrv1:~$ mamba install  -y --quiet --override-channels --channel conda-forge --channel bioconda --channel defaults --channel pytorch --channel ilastik-forge  fiji=20220414 python=3.7 fiji-max_inscribed_circles=1.1.2 fiji-ilastik=1.8.2
```

## Build Client fail after galaxy tag update

```bash
TASK [galaxyproject.galaxy : Build client] ******************************************************************************************************************************************************************************************************************************
fatal: [galaxyduboule.epfl.ch]: FAILED! => {"changed": false, "cmd": "/usr/bin/make client-production-maps", "msg": "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"\nwarning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"\nerror react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"\nerror Found incompatible module.\nmake: *** [Makefile:165: node-deps] Error 1", "rc": 2, "stderr": "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"\nwarning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"\nerror react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"\nerror Found incompatible module.\nmake: *** [Makefile:165: node-deps] Error 1\n", "stderr_lines": ["warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"", "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"", "error react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"", "error Found incompatible module.", "make: *** [Makefile:165: node-deps] Error 1"], "stdout": "cd client && yarn install --network-timeout 300000 --check-files\nyarn install v1.22.10\n[1/4] Resolving packages...\n[2/4] Fetching packages...\ninfo fsevents@2.3.2: The platform \"linux\" is incompatible with this module.\ninfo \"fsevents@2.3.2\" is an optional dependency and failed compatibility check. Excluding it from installation.\ninfo Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.\n", "stdout_lines": ["cd client && yarn install --network-timeout 300000 --check-files", "yarn install v1.22.10", "[1/4] Resolving packages...", "[2/4] Fetching packages...", "info fsevents@2.3.2: The platform \"linux\" is incompatible with this module.", "info \"fsevents@2.3.2\" is an optional dependency and failed compatibility check. Excluding it from installation.", "info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command."]}
```

I used python to get it correctly:

```python
>>> msg = {"changed": false, "cmd": "/usr/bin/make client-production-maps", "msg": "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"\nwarning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"\nerror react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"\nerror Found incompatible module.\nmake: *** [Makefile:165: node-deps] Error 1", "rc": 2, "stderr": "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"\nwarning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"\nerror react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"\nerror Found incompatible module.\nmake: *** [Makefile:165: node-deps] Error 1\n", "stderr_lines": ["warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"", "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"", "error react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"", "error Found incompatible module.", "make: *** [Makefile:165: node-deps] Error 1"], "stdout": "cd client && yarn install --network-timeout 300000 --check-files\nyarn install v1.22.10\n[1/4] Resolving packages...\n[2/4] Fetching packages...\ninfo fsevents@2.3.2: The platform \"linux\" is incompatible with this module.\ninfo \"fsevents@2.3.2\" is an optional dependency and failed compatibility check. Excluding it from installation.\ninfo Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.\n", "stdout_lines": ["cd client && yarn install --network-timeout 300000 --check-files", "yarn install v1.22.10", "[1/4] Resolving packages...", "[2/4] Fetching packages...", "info fsevents@2.3.2: The platform \"linux\" is incompatible with this module.", "info \"fsevents@2.3.2\" is an optional dependency and failed compatibility check. Excluding it from installation.", "info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command."]}
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
NameError: name 'false' is not defined. Did you mean: 'False'?
>>> msg = {"changed": False, "cmd": "/usr/bin/make client-production-maps", "msg": "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"\nwarning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"\nerror react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"\nerror Found incompatible module.\nmake: *** [Makefile:165: node-deps] Error 1", "rc": 2, "stderr": "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"\nwarning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"\nerror react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"\nerror Found incompatible module.\nmake: *** [Makefile:165: node-deps] Error 1\n", "stderr_lines": ["warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.0.0\"", "warning Resolution field \"chokidar@3.5.2\" is incompatible with requested version \"chokidar@^2.1.8\"", "error react-styleguidist@11.1.7: The engine \"node\" is incompatible with this module. Expected version \">=14\". Got \"12.16.3\"", "error Found incompatible module.", "make: *** [Makefile:165: node-deps] Error 1"], "stdout": "cd client && yarn install --network-timeout 300000 --check-files\nyarn install v1.22.10\n[1/4] Resolving packages...\n[2/4] Fetching packages...\ninfo fsevents@2.3.2: The platform \"linux\" is incompatible with this module.\ninfo \"fsevents@2.3.2\" is an optional dependency and failed compatibility check. Excluding it from installation.\ninfo Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.\n", "stdout_lines": ["cd client && yarn install --network-timeout 300000 --check-files", "yarn install v1.22.10", "[1/4] Resolving packages...", "[2/4] Fetching packages...", "info fsevents@2.3.2: The platform \"linux\" is incompatible with this module.", "info \"fsevents@2.3.2\" is an optional dependency and failed compatibility check. Excluding it from installation.", "info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command."]}
>>> print(msg['msg'])
warning Resolution field "chokidar@3.5.2" is incompatible with requested version "chokidar@^2.0.0"
warning Resolution field "chokidar@3.5.2" is incompatible with requested version "chokidar@^2.1.8"
error react-styleguidist@11.1.7: The engine "node" is incompatible with this module. Expected version ">=14". Got "12.16.3"
error Found incompatible module.
make: *** [Makefile:165: node-deps] Error 1
>>> print(msg['stderr'])
warning Resolution field "chokidar@3.5.2" is incompatible with requested version "chokidar@^2.0.0"
warning Resolution field "chokidar@3.5.2" is incompatible with requested version "chokidar@^2.1.8"
error react-styleguidist@11.1.7: The engine "node" is incompatible with this module. Expected version ">=14". Got "12.16.3"
error Found incompatible module.
make: *** [Makefile:165: node-deps] Error 1
>>> print(msg['stdout'])
cd client && yarn install --network-timeout 300000 --check-files
yarn install v1.22.10
[1/4] Resolving packages...
[2/4] Fetching packages...
info fsevents@2.3.2: The platform "linux" is incompatible with this module.
info "fsevents@2.3.2" is an optional dependency and failed compatibility check. Excluding it from installation.
info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.
```

I asked help on gitter and @hexylena spotted that the error was that the node version was too low. @nsoranzo proposed to remove the virtual env of galaxy as it will recreate it with a compatible version of node. @dannon confirmed it was `${galaxy_root}/venv/` which in my case is `/data/galaxy/galaxy/venv/`. Therefore I ssh to my server and did `sudo rm -rf /data/galaxy/galaxy/venv/`. Then I relaunched the playbook. I could see:

```bash
TASK [galaxyproject.galaxy : Create additional privilege separated directories] ***********************
changed: [galaxyduboule.epfl.ch] => (item=/data/galaxy/galaxy/venv)
ok: [galaxyduboule.epfl.ch] => (item=/data/galaxy/galaxy/server)
ok: [galaxyduboule.epfl.ch] => (item=/data/galaxy/galaxy/config)
ok: [galaxyduboule.epfl.ch] => (item=/data/galaxy/galaxy/local_tools)
...
TASK [galaxyproject.galaxy : Create Galaxy virtualenv] ************************************************
changed: [galaxyduboule.epfl.ch]
...

TASK [galaxyproject.galaxy : Report preferred Node.js version] ****************************************
ok: [galaxyduboule.epfl.ch] => {
    "galaxy_node_version": "14.15.0"
}

TASK [galaxyproject.galaxy : Install node] ************************************************************
changed: [galaxyduboule.epfl.ch]

```

Thank you so much the galaxy admins. You are my heroes.

Unfortunately I ran into another error on galaxy.

## Downgrade galaxy

I tried to upgrade to 22.01 and I got issues, then I wanted to downgrade. Simply changing the galaxy_tag in the playbook does not work. You first need to activate the galaxy virtual environment and downgrade the database:

```bash
cd /data/galaxy/galaxy/server
./manage_db.sh -c ../config/galaxy.yml downgrade 179
```

Then relauch the playbook worked.

I just got a curious error about permission denied which I solved with

```bash
sudo chown -R galaxy:galaxy /data/galaxy/galaxy/server/database/cache/
```

## Node in drained status

I got multiple times:
```bash
$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
main*        up   infinite      1  drain localhost
```

The solution is:
```bash
sudo scontrol update nodename=localhost state=idle
```

## Delete all shared workflow of a user who has been deleted

Thanks to @hrhotz

```bash
# Become postgres user
sudo su - postgres
# Open the galaxy database
psql -d galaxy
# Find the user_id
select * from stored_workflow where name like '%Ensembl%' and published = 'true';
# Select and check the workflows to delete
select * from stored_workflow where user_id = 11 and published = 'true';
# Mark them as deleted
update stored_workflow set deleted = 't' where user_id = 11 and published = 'true';
# Check it changed:
select * from stored_workflow where user_id = 11 and published = 'true';
# Youhou
```
