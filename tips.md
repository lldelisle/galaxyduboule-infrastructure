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
