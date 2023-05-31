# Geoff's node bootstrapper

## gets a node ready for kubernetes

Environment variables:

```sh
GEOFF_RESET_CEPH=1 # reset ceph data

GEOFF_RESET_KUBE=1 # reset kubernetes data
```

You may want to reset ceph and kubernetes data if you are reusing a node that was previously used for development; as both of these systems will go through quite a bit of effort to make sure that data is not lost.


Code is meant to be self documenting.  There are some assumptions though that are derived from what rancher seems to want:

Nodes run at 10.10.1.1/24; so after a couple hundreds nodes were gonna have to move on.

