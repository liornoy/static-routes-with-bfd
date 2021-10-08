# FRR BFD Session

This version of the setup simulate a BFD connection between a Kubernetes cluster nodes to data center gateways that are more than one hop away. 

![diffNetVersion](https://user-images.githubusercontent.com/40122521/136552206-a8b42573-17c8-42ba-9750-0cd9cc61cbea.png)

The setup.sh script takes care of all the setup needed. the steps it makes are:
1. Create a kind cluster with two worker nodes
2. Create a docker sub-network called kind2
3. Create the middle linux container and connect it to both networks
4. Create two frr containers
5. Edit configurations files
6. Create configmap
7. Apply the FRR daemonset
8. Restart the containers to apply the configurations
9. Add static routes

### Verify the BFD session is up
To verify that the BFD session is up, enter one of the containers:

`docker exec -it frr1 sh`

Enter to the vtysh (FRR's shell) and inspect the bfd peers:

```
vtysh
show bfd peers brief
```

Output should look like this:
```
Session count: 2
SessionId  LocalAddress                             PeerAddress                             Status         
=========  ============                             ===========                             ======         
4161101689 172.19.0.3                               172.18.0.2                              up             
1130635521 172.19.0.3                               172.18.0.3                              up 
```

### Simulate a failover

To simulate a failover we'll delete one of the worker nodes:


`kubectl delete node kind-worker`

Then watch the BFD status from the container again:
```
Session count: 2
SessionId  LocalAddress                             PeerAddress                             Status         
=========  ============                             ===========                             ======         
4161101689 172.19.0.3                               172.18.0.2                              up             
1130635521 172.19.0.3                               172.18.0.3                              down 
```
#### Cleanup
Use the cleanup.sh script to delete the environment

