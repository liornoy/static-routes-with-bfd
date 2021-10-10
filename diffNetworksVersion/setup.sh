kind create cluster --name kind --config cluster.yaml

echo "Creating second docker network kind2" 
docker network create --ipv6 --driver=bridge kind2 --subnet=172.19.0.0/16 --subnet=fc00:f853:ccd:e798::/64

echo "Creating frr containers"
docker run --network kind2 -d -it --rm --name next-hop-router  alpine
docker network connect kind next-hop-router 

docker run --network kind2 -d --rm --name frr1 --privileged -v "$(pwd)/frr1":/etc/frr frrouting/frr
docker run --network kind2 -d --rm --name frr2 --privileged -v "$(pwd)/frr2":/etc/frr frrouting/frr

frr1_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' frr1)
frr2_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' frr2)
node1_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-worker)
node2_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-worker2)

echo "Editing configurations files"
cp frr.conf.tmpl frr.conf
cp frr.conf configmap/
sed -i 's/IP_A/'"$node1_ip"'/g' frr.conf
sed -i 's/IP_B/'"$node2_ip"'/g' frr.conf
cp frr.conf frr1/
sed -i 's/LOCAL_IP/'"$frr1_ip"'/g' frr1/frr.conf
cp frr.conf frr2/
sed -i 's/LOCAL_IP/'"$frr2_ip"'/g' frr2/frr.conf
sed -i 's/IP_A/'"$frr1_ip"'/g' configmap/frr.conf
sed -i 's/IP_B/'"$frr2_ip"'/g' configmap/frr.conf

kubectl create configmap frr-config --from-file=./configmap/
kubectl apply -f daemonset.yaml
docker restart frr1 frr2

echo "Configuring static routes"
docker exec  frr1 sh -c "ip route add 172.18.0.0/16 via 172.19.0.2 dev eth0"
docker exec  frr2 sh -c "ip route add 172.18.0.0/16 via 172.19.0.2 dev eth0"
docker exec kind-worker sh -c "ip route add 172.19.0.0/16 via 172.18.0.5 dev eth0"
docker exec kind-worker2 sh -c "ip route add 172.19.0.0/16 via 172.18.0.5 dev eth0"
