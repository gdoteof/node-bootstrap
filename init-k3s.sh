TOKEN=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64 ; echo '')
echo using $TOKEN

curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN sh -s - server --cluster-init
