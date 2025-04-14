netnsName="lux"
outLink="ens19"
v4Addr="10.0.2.103/24"
v4Gateway="10.0.2.1"
v6Addr="2605:6400:c6ec:103::/64"
v6Gateway="2605:6400:c6ec::1"

ip netns add "$netnsName"
ip link set "$outLink" netns "$netnsName"

ip netns exec "$netnsName" ip link set lo up
ip netns exec "$netnsName" ip link set "$outLink" up

ip netns exec "$netnsName" ip address add "$v4Addr" dev "$outLink"
ip netns exec "$netnsName" ip route add default dev "$outLink" via "$v4Gateway"
ip netns exec "$netnsName" ip -6 address add "$v6Addr" dev "$outLink"
ip netns exec "$netnsName" ip -6 route add default dev "$outLink"
ip netns exec "$netnsName" ip -6 neigh  # wait until find gateway
ip netns exec "$netnsName" ip -6 route change default via "$v6Gateway"

