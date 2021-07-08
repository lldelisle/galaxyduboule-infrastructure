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

