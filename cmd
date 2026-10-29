NS=apigee-auth
ING=nginx-ingress-nginx-controller-apiauth-6957df44dc-lrkqj
VOLVO=7fd6da5d-db47-4694-b530-01b920cf95bc
DESDE=2026-10-27T09:00:00Z


kubectl get pods -n $NS | tee ev_A1_pods.txt
  
kubectl logs -n $NS $ING --since-time=$DESDE | grep -a "$VOLVO" \
 | awk '$4 ~ /27\/Oct\/2026:09:[0-2]/ {print $4, $3, $7, $9}' | tee ev_A2_volvo_ingress.txt

  kubectl logs -n $NS $ING --since-time=$DESDE \
 | awk '$4 ~ /27\/Oct\/2026:09:/ && $9 ~ /^5/' | tee ev_A3_5xx.txt | wc -l

kubectl logs -n $NS $ING --since-time=$DESDE \
 | grep -aE "upstream timed out|connect\(\) failed|upstream prematurely closed|no live upstreams" \
 | grep -a "2026/10/27 09:" | tee ev_A4_upstream.txt | wc -l

kubectl logs -n $NS $ING --since-time=$DESDE \
 | grep -aE "upstream timed out|connect\(\) failed|upstream prematurely closed|no live upstreams" \
 | grep -a "2026/10/27 09:" | tee ev_A4_upstream.txt | wc -l


kubectl get pods -A | grep -i volvo | tee ev_B1_pods_volvo.txt
NSV=<namespace>; PODV=<pod-del-frontend>

kubectl logs -n $NSV $PODV --since-time=$DESDE | grep -a "upstream timed out" | grep -a "api-auth" > ev_B2_timeouts.txt
head -1 ev_B2_timeouts.txt; tail -1 ev_B2_timeouts.txt; wc -l < ev_B2_timeouts.txt

kubectl logs -n $NSV $PODV --since-time=$DESDE | grep -a "api-auth/authentication/oauth/token" \
 | awk '{print $9}' | sort | uniq -c | tee ev_B3_codigos.txt

kubectl exec -n $NSV $PODV -- sh -c 'grep -rn -B2 -A6 "api-auth" /etc/nginx/' | tee ev_B4_config.txt

kubectl exec -n $NSV $PODV -- curl -skv --connect-timeout 5 -o /dev/null https://107.246.192.47/authentication/oauth/token 2>&1 | tail -5 | tee ev_B6_ip.txt
kubectl exec -n $NSV $PODV -- curl -skv --connect-timeout 5 -o /dev/null https://<hostname>/authentication/oauth/token 2>&1 | tail -5 | tee -a ev_B6_ip.txt


nslookup 107.246.192.47
Invoke-RestMethod https://rdap.arin.net/registry/ip/107.246.192.47 | Select-Object name, handle, startAddress, endAddress

