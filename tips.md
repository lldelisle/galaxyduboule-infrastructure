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

```
sudo su - galaxy
/data/galaxy/galaxy/var/dependencies/_conda/bin/python /data/galaxy/galaxy/var/dependencies/_conda/bin/conda create -y --quiet --override-channels --channel conda-forge --channel bioconda --channel defaults -p /data/galaxy/galaxy/var/dependencies/_conda/envs/mulled-v1-c9f488ec0e9a96bed61dcc2e074b26ce37ed596751861ff368fd824a2a5f11d4 htseq=0.9.1 samtools=1.7 python=3.8
```

I got an error: `samtools: error while loading shared libraries: libcrypto.so.1.0.0: cannot open shared object file: No such file or directory` which is classical with old samtools with new openssl.

Finally @cat-bro gave me the list of the mulled which worked and the solution was:

```
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