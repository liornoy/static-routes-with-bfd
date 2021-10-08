# FRR BFD Session
In this document, I will describe how to set up an environment and simulate a BFD session (using [FRR](https://frrouting.org/))
between Kind cluster with two nodes - and an external container.
## Prerequisites
- Go 1.15+
- Python 3
- KIND - Kubernetes in Docker
- kubectl

## Setting up a development environment
Clone the metallb [repository](https://github.com/metallb/metallb).
From the root of your git clone, run:

`inv dev-env -p bgp`

This command will create a Kubernetes cluster with 2 nodes and a FRR container.
## Create the FRR pods
First you'll need to create a configmap with all the BFD configurations.
After you cloned this repository, enter:

`k create configmap frr-config --from-file=./configmap/`

The configmap folder includes:
```
configmap
|   daemons
|   frr.conf
|   vtysh.conf
```

Apply the daemonset yaml:

`k apply -f daemonset.yaml`

The daemonset will inject those files into the etc/frr directory in the FRR pods.

## Configure the FRR container
First, inspect the pod's IP addresses:

`k get pods -o wide`

Then edit the frr.conf file inside the frr-container folder and paste the IP addresses:
```
bfd
 peer 172.18.0.X
   no shutdown
 !
 peer 172.18.0.Y
   no shutdown
 !
!
```
Next, enter the FRR container:

`docker exec -it frr sh`

In daemons file edit bfdd from "no" to "yes".
In frr.conf paste the contant of frr-container/frr.conf.
```
cd etc/frr
vi daemons
vi frr.conf
```
We then restart the container to apply the new configurations.
```
exit
docker restart frr
```
## Test the BFD session
In this point, the BFD session should be up and running. Let's assert this:
```
docker exec -it frr sh
vtysh
sh bfd peers brief
```
The output should look like this:
```
Session count: 2
SessionId  LocalAddress                             PeerAddress                             Status         
=========  ============                             ===========                             ======         
2917389698 172.18.0.5                               172.18.0.4                              up             
1501100564 172.18.0.5                               172.18.0.3                              up  
```
Now, delete one of the pods from the kind cluster, and check the connectivity again from the container.
This time it should look like this:
```
Session count: 2
SessionId  LocalAddress                             PeerAddress                             Status         
=========  ============                             ===========                             ======         
2917389698 172.18.0.5                               172.18.0.4                              up             
1501100564 172.18.0.5                               172.18.0.3                              down 
```
___
For clean up enter:
`inv dev-env-cleanup`

