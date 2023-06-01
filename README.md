# Geoff's node bootstrapper

## gets a node ready for kubernetes

This is really oriented not just around a kubernetes cluster, but specifically a ceph backed kubernetes cluster running on baremetal.

The idea is that you call Step1, then Step2, then Step3. There are multiple options for the second and third step, depending on what you want to do and what your hardware is.

My main constraint was running on orangepi/nanopi rockchip boards that only have a single drive slot. In those cases, Step 2 here is going to take an nvme drive and cut out 20% of it to mount /var on (I am booting from TF card which is slow, and definitely not great for etcd). In some cases, I have both a SATA and an NVME which are suitable for /var, so I have a Step 2 for that as well, which uses an entire drive for the /root fs, making the /var specific mount superfluous.

Step 3 is actually joining the cluster; which is different depending on if you are the first master node, if you are a redundant master node, or if you are a worker node.. I have called the master+worker node "god" nodes.

This code is not meant to be run as a script by you (it does work for my use case), but rather as a set of instructions. You will need to edit the code to suit your needs if you want to do similar things. If you use exactly the same hardware as me, you can probably just run it as is.

There are two different k3s configs, one for masters, one for workers.  The config for the first master and any followups are the same.

There are also a set of helm chart addons in the helmAddons folder which install the following charts

- cert-manager
- rook-ceph
- prometheus-stack


Environment variables:

```sh
GEOFF_VAR_MOUNT=1 # make a mount for /var
GEOFF_RESET_RANCHER=1 # reset kubernetes data
GEOFF_RESET_CEPH=1 # reset kubernetes data
```

You may want to reset ceph and kubernetes data if you are reusing a node that was previously used for development; as both of these systems will go through quite a bit of effort to make sure that data is not lost.

Code is meant to be self documenting. There are some assumptions though that are derived from what rancher seems to want:

- Nodes run at 10.10.1.1/24; so after a couple hundreds nodes were gonna have to move on.

## Usage

```sh
SKIP_VAR_MOUNT=0 GEOFF_RESET_RANCHER=1 GEOFF_RESET_CEPH=1 ./Step_01__PrepareOs.sh && ./Step_02__<yoursetup>__PrepareDrives.sh
# if you did not skip the var mount, you should reset here

#init your kubernetes cluster on the first node, this will give you instructions on how to add more nodes
SKIP_VAR_MOUNT=0 GEOFF_RESET_RANCHER=1 GEOFF_RESET_CEPH=1 ./Step_03_init__PrepareOs.sh && ./Step_02__<yoursetup>__PrepareDrives.sh
```
