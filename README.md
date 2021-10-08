# static-rotutes-with-bfd
This repository is integration-like work that walks through the process of setting up a [BFD](https://en.wikipedia.org/wiki/Bidirectional_Forwarding_Detection) (Bidirectional Forwarding Detection) connection between a [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) cluster and external containers. The BFD is established using [FRR](https://frrouting.org/) (Free Range Routing).

There are two versions for this setup:


### sameNetwork -
Connection between two nodes and one external docker container - while all on the same network.


### diffNetworks -
connection between two nodes on one sub-network, and two external containers on different sub-network, and using middle container which functions like a router.
