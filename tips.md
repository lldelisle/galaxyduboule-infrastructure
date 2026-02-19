# Debugging/Tricks examples

## To increase priority of a job

`sudo scontrol update job=4191 Priority=4294967292`


## Give access to the server to someone new

```bash
sudo adduser <username>
# Answer the questions

# Get the user id and group id with
grep <username> /etc/passwd

# Impersonate to create a directory nas:
sudo su - <username>
mkdir nas
exit

# Update the /etc/fstab file so it has access to the nas
sudo vim /etc/fstab
sudo mount -a
sudo systemctl daemon-reload
```

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
sudo influx v1 shell
show databases
use telegraf
show measurements
```

For example, get the last measurements of "user-disk-usage":

```influx
SELECT * FROM "user-disk-usage" ORDER BY time DESC LIMIT 10;
```

To get the time as human readable:

```influx
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

If the state is draining then the command is:
```bash
sudo scontrol update nodename=localhost state=resume
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

## Use tool whose profile is above

I think I should not do that but...

I wanted to use deeptools_bigwig_average but the profile was 22.05 and I have 22.01.

First I installed the tool.

Then I modified the profile version in `/data/galaxy/galaxy/var/shed_tools/toolshed.g2.bx.psu.edu/repos/bgruening/deeptools_bigwig_average/4a53856a5b85/deeptools_bigwig_average/deepTools_macros.xml`

Then I added the tool to `/data/galaxy/galaxy/var/config/shed_tool_conf.xml`

## Influxdb data is taking too much space on '/'

First I stop influxdb:
```bash
sudo systemctl stop influxdb
```
Move the data to another place:
```bash
sudo mkdir /data/influxdb/
sudo chown influxdb:influxdb /data/influxdb/
sudo mv /var/lib/influxdb/data/ /data/influxdb/
```
Change the playbook by setting `influxdb_data_dir: "/data/influxdb_data/"`
Run playbook

## CVMFS Transport endpoint is not connected

I don't know what I am doing wrong but I often have:

```bash
$ ls /cvmfs/
ls: cannot access '/cvmfs/data.galaxyproject.org': Transport endpoint is not connected
data.galaxyproject.org
$ sudo cvmfs_config status
/usr/bin/cvmfs_config: line 1046: cd: /mnt/cvmfs: Transport endpoint is not connected
mountpoint /mnt/cvmfs inaccessible
/usr/bin/cvmfs_config: line 1046: cd: /cvmfs/data.galaxyproject.org: Transport endpoint is not connected
mountpoint /cvmfs/data.galaxyproject.org inaccessible
```

The solution I found is from https://cernvm-forum.cern.ch/t/cannot-mount-cvmfs-on-ubuntu-20-anymore/80/2:

```bash
sudo cvmfs_config umount
sudo systemctl restart autofs
sudo cvmfs_config setup
```

### if web interface refuses to open when Galaxy itself is running with no issues
Check if nginx is running 

```bash 
$: sudo systemctl status nginx
ls: × nginx.service - A high performance web server and a reverse proxy server
      Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
      Active: failed (Result: exit-code) since Tue 2025-09-23 06:23:13 CEST; 6 days ago
      Duration: 1w 4d 23h 25min 5.760s
      Docs: man:nginx(8)
      CPU: 15ms
```

if it shows "Active: failed (Result: exit-code)"

Try restarting `nginx`

```bash
sudo systemctl restart nginx
sudo systemctl status nginx
 ```

## To connect other ports on the server (8080 which is currently used by Jupyter lab).

Try checking if this works 

```bash
nc -vz 192.168.202.69 8080
```

If it does, then just connect using SSH port forwarding to a local port of your choice (the first 8080) below

```bash
ssh -L 8080:localhost:8080 oadebayo@192.168.202.69
```
Then 

```bash
http://localhost:8080
```

## To connect a user to higlass on the duboule server

Add the user to the `docker` group where the current higlass docker container is running and `higlass` group (those who have the right permisions to the directory `/home/higlass/` on the server)

First confirm that the user is not already in the groups (sudo access required)

```bash
sudo getent group docker
sudo getent group higlass
```
if the user is not in any of the groups or in both, add them using the following commands

```bash
sudo usermod -aG docker username
sudo usermod -aG higlass username
```

Then the user (no sudo access required) can now open a port (10001) on their local PC and connect it to to port 8060 where the higlass docker container is currently running by running the following from the local PC (not on the duboule seerver)

```bash
ssh -f -N -L 10001:127.0.0.1:8060 username@192.168.202.69
```

Don't be alarmed, you won't see any output returned, its been silenced by the flag `-f`, remove it to keep the shell active and be aware when the port closes.

The run

```bash
http://localhost:10001
```
or 

```bash
http://127.0.0.1:10001
```
## To upload chromosomes, genes or .mcool/cool files into higlass, visit the following official higlass.

To add a new genome

make sure the file `exonU.py` is in the same director before running it

exonU.py

```py
from __future__ import print_function

__author__ = "Alaleh Azhir,Peter Kerpedjiev"

import collections as col
import sys
import argparse


class GeneInfo:
    def __init__(self):
        pass


def merge_gene_info(gene_infos, gene_info):
    """
    Add a new gene_info. If it's txStart and txEnd overlap with a previous entry for this
    gene, combine them.
    """
    merged = False

    for existing_gene_info in gene_infos[gene_info.geneId]:
        if (
            existing_gene_info.chrName == gene_info.chrName
            and existing_gene_info.txEnd > gene_info.txStart
            and gene_info.txEnd > existing_gene_info.txStart
        ):

            # overlapping genes, merge the exons of the second into the first
            existing_gene_info.txStart = min(
                existing_gene_info.txStart, gene_info.txStart
            )
            existing_gene_info.txEnd = max(existing_gene_info.txEnd, gene_info.txEnd)

            for (exon_start, exon_end) in gene_info.exonUnions:
                existing_gene_info.exonUnions.add((exon_start, exon_end))

            merged = True

    if not merged:
        gene_infos[gene_info.geneId].append(gene_info)

    return gene_infos


def main():
    parser = argparse.ArgumentParser(
        description="""

    python ExonUnion.py Calculate the union of the exons of a list
    of transcript.

    chr10   27035524        27150016        ABI1    76      -       NM_001178120    10006   protein-coding  abl-interactor 1        27037498        27149792        10      27035524,27040526,27047990,27054146,27057780,27059173,27060003,27065993,27112066,27149675,      27037674,27040712,27048164,27054247,27057921,27059274,27060018,27066170,27112234,27150016,
"""
    )

    parser.add_argument("transcript_bed")
    # parser.add_argument('-o', '--options', default='yo',
    # help="Some option", type='str')
    # parser.add_argument('-u', '--useless', action='store_true',
    # help='Another useless option')
    args = parser.parse_args()

    inputFile = open(args.transcript_bed, "r")

    gene_infos = col.defaultdict(list)

    for line in inputFile:
        words = line.strip().split("\t")

        gene_info = GeneInfo()

        try:
            gene_info.chrName = words[0]
            gene_info.txStart = words[1]
            gene_info.txEnd = words[2]
            gene_info.geneName = words[3]
            gene_info.score = words[4]
            gene_info.strand = words[5]
            gene_info.refseqId = words[6]
            gene_info.geneId = words[7]
            gene_info.geneType = words[8]
            gene_info.geneDesc = words[9]
            gene_info.cdsStart = words[10]
            gene_info.cdsEnd = words[11]
            gene_info.exonStarts = words[12]
            gene_info.exonEnds = words[13]
        except:
            print("ERROR: line:", line, file=sys.stderr)
            continue

        # for some reason, exon starts and ends have trailing commas
        gene_info.exonStartParts = gene_info.exonStarts.strip(",").split(",")
        gene_info.exonEndParts = gene_info.exonEnds.strip(",").split(",")
        gene_info.exonUnions = set(
            [
                (int(s), int(e))
                for (s, e) in zip(gene_info.exonStartParts, gene_info.exonEndParts)
            ]
        )

        # add this gene info by checking whether it overlaps with any existing ones
        gene_infos = merge_gene_info(gene_infos, gene_info)

    for gene_id in gene_infos:
        for contig in gene_infos[gene_id]:
            output = "\t".join(
                map(
                    str,
                    [
                        contig.chrName,
                        contig.txStart,
                        contig.txEnd,
                        contig.geneName,
                        contig.score,
                        contig.strand,
                        "union_" + gene_id,
                        gene_id,
                        contig.geneType,
                        contig.geneDesc,
                        contig.cdsStart,
                        contig.cdsEnd,
                        ",".join([str(e[0]) for e in sorted(contig.exonUnions)]),
                        ",".join([str(e[1]) for e in sorted(contig.exonUnions)]),
                    ],
                )
            )
            print(output)


if __name__ == "__main__":
    main()
```
Then create a bash script genome.sh and paste the  command below in it. Edit the genome `ASSEMBLY` and  `TAXID` name in the following script.  Adjust `DATADIR` if needed.

```bash
#!/usr/bin/env bash
set -euo pipefail

############################################
# Configuration
############################################
ASSEMBLY=mm39
TAXID=10090
DATADIR="$HOME/data"
TMPDIR="$DATADIR/$ASSEMBLY/tmp"

# Ensure deterministic sort for join
export LC_ALL=C

############################################
# Directories
############################################
mkdir -p "$DATADIR/genbank"
mkdir -p "$DATADIR/$ASSEMBLY"
mkdir -p "$TMPDIR"

############################################
# Download NCBI data
############################################
wget -N -P "$DATADIR/genbank" ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2refseq.gz
wget -N -P "$DATADIR/genbank" ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz
wget -N -P "$DATADIR/genbank" ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene2pubmed.gz

############################################
# Download UCSC refGene
############################################
wget -N -P "$DATADIR/$ASSEMBLY" \
  http://hgdownload.cse.ucsc.edu/goldenPath/$ASSEMBLY/database/refGene.txt.gz

############################################
# Filter NCBI data by species
############################################
zcat "$DATADIR/genbank/gene2refseq.gz" \
  | awk -v tax="$TAXID" '$1==tax' \
  > "$DATADIR/$ASSEMBLY/gene2refseq"

zcat "$DATADIR/genbank/gene_info.gz" \
  | awk -v tax="$TAXID" '$1==tax' \
  | sort -k2,2 \
  > "$DATADIR/$ASSEMBLY/gene_info"

zcat "$DATADIR/genbank/gene2pubmed.gz" \
  | awk -v tax="$TAXID" '$1==tax' \
  > "$DATADIR/$ASSEMBLY/gene2pubmed"

############################################
# Prepare refGene (sorted on RefSeq ID)
############################################
zcat "$DATADIR/$ASSEMBLY/refGene.txt.gz" \
  | awk -F $'\t' '$3 !~ /_/' \
  | sort -k2,2 \
  > "$DATADIR/$ASSEMBLY/refGene_sorted"

############################################
# GeneID -> RefSeq mapping (lexicographic sort, not numeric)
############################################
awk -F $'\t' '{
  split($4,a,".");
  if (a[1]!="-") gsub(/\r/,""); print $2 "\t" a[1];
}' "$DATADIR/$ASSEMBLY/gene2refseq" \
  | sort -k1,1 \
  | uniq \
  > "$TMPDIR/geneid_refseqid.sorted"

############################################
# Count PubMed citations (lexicographic sort, not numeric)
############################################
awk '{gsub(/\r/,""); print $2}' "$DATADIR/$ASSEMBLY/gene2pubmed" \
  | sort \
  | uniq -c \
  | awk '{gsub(/\r/,""); print $2 "\t" $1}' \
  | sort -k1,1 \
  > "$TMPDIR/gene2pubmed-count.sorted"

############################################
# Join GeneID -> RefSeq -> citation count
############################################
join -1 1 -2 1 \
  "$TMPDIR/geneid_refseqid.sorted" \
  "$TMPDIR/gene2pubmed-count.sorted" \
  | sort -k2,2 \
  > "$DATADIR/$ASSEMBLY/geneid_refseqid_count"

############################################
# Join RefSeq gene model (join on RefSeq ID)
############################################
sort -k2,2 "$DATADIR/$ASSEMBLY/geneid_refseqid_count" > "$TMPDIR/a"
sort -k2,2 "$DATADIR/$ASSEMBLY/refGene_sorted"        > "$TMPDIR/b"

join -1 2 -2 2 "$TMPDIR/a" "$TMPDIR/b" \
 | awk '{
     print $2 "\t" $1 "\t" $5 "\t" $6 "\t" \
           $7 "\t" $8 "\t" $9 "\t" $10 "\t" \
           $11 "\t" $12 "\t" $13 "\t" $3
   }' \
 | sort -k1,1 \
 > "$DATADIR/$ASSEMBLY/geneid_refGene_count"

############################################
# Join citation counts with gene info
############################################
awk '{gsub(/\r/,""); print}' "$DATADIR/$ASSEMBLY/gene_info" | sort -k2,2 > "$TMPDIR/c"
awk '{gsub(/\r/,""); print}' "$TMPDIR/gene2pubmed-count.sorted" | sort -k1,1 > "$TMPDIR/d"

join -1 2 -2 1 -t $'\t' "$TMPDIR/c" "$TMPDIR/d" \
 | awk -F $'\t' '{print $1 "\t" $3 "\t" $10 "\t" $12 "\t" $16}' \
 | sort -k1,1 \
 > "$DATADIR/$ASSEMBLY/gene_subinfo_citation_count"

############################################
# Final annotation BED
############################################
join -t $'\t' \
  "$DATADIR/$ASSEMBLY/gene_subinfo_citation_count" \
  "$DATADIR/$ASSEMBLY/geneid_refGene_count" \
| awk -F $'\t' '{
    print $7 "\t" $9 "\t" $10 "\t" $2 "\t" $16 "\t" \
          $8 "\t" $6 "\t" $1 "\t" $3 "\t" $4 "\t" \
          $11 "\t" $12 "\t" $14 "\t" $15
  }' \
> "$DATADIR/$ASSEMBLY/geneAnnotations.bed"

############################################
# Exon union
############################################
wget -N https://raw.githubusercontent.com/higlass/clodius/develop/scripts/exonU.py

python exonU.py \
  "$DATADIR/$ASSEMBLY/geneAnnotations.bed" \
  > "$DATADIR/$ASSEMBLY/geneAnnotationsExonUnions.bed"

############################################
# Cleanup
############################################
rm -rf "$TMPDIR"

echo "✅ Pipeline completed successfully"
```

make sure the file as appropriate permisions (`sudo +x assembly.sh`)
```bash
bash assembly.sh
```
The needed output is the file `geneAnnotationsExonUnions.bed`, the output of `exonU.py`.

Move this file and the chromosome_sizes file into `home/higlass/microC_Shared/hg-tmp/`, then run the following command to generate higlass's special Gene annotation file type:

```sh
docker exec higlass_microC_shared clodius aggregate bedfile     --max-per-tile 20     --importance-column 5     --chromsizes-filename /tmp/mm39.chrom.sizes    --output-file /tmp/gene-annotations-mm39.db     --delimiter $'\t'     /tmp/geneAnnotationsExonUnions.bed
```
then run the following to Injest the Gene Annotations into higlass (UI)

```sh
docker exec higlass_microC_shared   python higlass-server/manage.py ingest_tileset   --filename /tmp/gene-annotations-mm39.db   --filetype beddb   --datatype gene-annotation  --name "Gene Annotations (mm39)"   --project-name "Gene Annotations"   --coordSystem mm39
```
Injest the chromosome files into higlass (UI) using:

```bash
docker exec higlass_microC_shared   python higlass-server/manage.py ingest_tileset   --filename /tmp/mm39.chrom.sizes   --filetype chromsizes-tsv   --datatype chromsizes   --name "Chromosomes (mm39)"   --project-name "Chromosomes"   --coordSystem mm39
```
To add .cool or .mcool files e.g., `trial.cool` first add them to the tmp folder in `/home/higlass/microC_Shared/hg-tmp/` then

```bash
docker exec higlass_microC_shared python higlass-server/manage.py ingest_tileset --filename /tmp/trial.cool --filetype cooler --datatype matrix --project-name micro_c
```

Adjust the value of `--project-name` (micro_c) as you wish

Note: the example above added `mm39` chromosome sizes and gene annotations to higlass, adjust to the name of your genome assembly.