cd /tmp
NS=apigee-auth
ING=nginx-ingress-nginx-controller-apiauth-6957df44dc-lrkqj
IDS="27b381d3-14b2-46d9-b7d4-210b47a076ad|7fd6da5d-db47-4694-b530-01b920cf95bc|0952a327-5300-4127-bb68-241f9031eb65"
TOK="20524fae-0261-447e-9205-c57405dccbac"
SOS=$(kubectl get pods -n $NS -o name | grep sos- | cut -d/ -f2)
OUT=/tmp/evidencias_apigee_auth.txt

kubectl logs -n $NS $ING > /tmp/ing.log
for p in $SOS; do kubectl logs -n $NS $p > /tmp/$p.log; done
ls -lh /tmp/ing.log /tmp/sos-*.log


{
echo "=== CONTEXTO ==="
echo "Cluster: $(kubectl config current-context)"
echo "Namespace: $NS | Dia analizado: 26/10/2026 | Horas en UTC | Generado: $(date -u '+%Y-%m-%d %H:%M UTC')"

echo; echo "=== 1. Estado de los pods ==="
kubectl get pods -n $NS

echo; echo "=== 2. Codigos HTTP del ingress (lunes) ==="
grep -a "26/Oct/2026" /tmp/ing.log | awk '{print $9}' | sort | uniq -c | sort -rn

echo; echo "=== 3. Respuestas 5xx (lunes) ==="
grep -a "26/Oct/2026" /tmp/ing.log | awk '$9 ~ /^5[0-9][0-9]$/ {print $4, $3, $7, $9}'
echo "Total 5xx: $(grep -a "26/Oct/2026" /tmp/ing.log | awk '$9 ~ /^5[0-9][0-9]$/' | wc -l)"

echo; echo "=== 4. Errores de upstream (lunes) ==="
grep -a "2026/10/26" /tmp/ing.log | grep -aE "upstream timed out|connect\(\) failed|upstream prematurely closed|no live upstreams"
echo "Total errores upstream: $(grep -a "2026/10/26" /tmp/ing.log | grep -acE "upstream timed out|connect\(\) failed|upstream prematurely closed|no live upstreams")"

echo; echo "=== 5. Peticiones de token de las apps de la incidencia (lunes) ==="
grep -a "26/Oct/2026" /tmp/ing.log | grep -aE "$IDS" | awk '{print $3, $7, $9}' | sort | uniq -c

echo; echo "=== 6. Peticiones de token por hora (lunes) ==="
grep -a "26/Oct/2026" /tmp/ing.log | grep -aE "$IDS" | awk '{print substr($4,14,2)"h", $9}' | sort | uniq -c

echo; echo "=== 7. Respuestas de token mas lentas (lunes, segundos) ==="
grep -a "26/Oct/2026" /tmp/ing.log | grep -a "oauth/token" \
 | awk '{for(i=1;i<=NF;i++) if($i ~ /^\[apigee-auth-sos/) print $(i-1), $4, $3}' | sort -rn | head -5

echo; echo "=== 8. Errores en sos para las apps de la incidencia (lunes) ==="
for p in $SOS; do echo "$p: $(grep -a '^2026-10-26' /tmp/$p.log | grep -aE "$IDS" | grep -aicE 'error|exception|invalid|denied|expired')"; done

echo; echo "=== 9. Introspecciones totales vs rechazadas (lunes) ==="
for p in $SOS; do
  T=$(grep -a '^2026-10-26' /tmp/$p.log | grep -ac "Entering introspection")
  R=$(grep -a '^2026-10-26' /tmp/$p.log | grep -a "Access Token" | grep -ac "not recognised")
  echo "$p total=$T rechazadas=$R"
done

echo; echo "=== 10. Tokens rechazados (lunes) ==="
for p in $SOS; do grep -a '^2026-10-26' /tmp/$p.log | grep -a "Access Token" | grep -a "not recognised" | cut -d"'" -f2; done | sort | uniq -c | sort -rn

echo; echo "=== 11. Token $TOK: lineas que no son introspeccion/fallo y primera aparicion ==="
for p in $SOS; do
  echo "-- $p"
  grep -a "$TOK" /tmp/$p.log | grep -avE "introspection|Failed to find|not recognised"
  echo "Primera aparicion: $(grep -a -m1 "$TOK" /tmp/$p.log | cut -c1-23)"
done

echo; echo "=== 12. Escaneo de seguridad Qualys (lunes) ==="
grep -a "26/Oct/2026" /tmp/ing.log | grep -a "SAN-VSS-WAS" | awk '{print $3}' | sort | uniq -c
for p in $SOS; do grep -a '^2026-10-26' /tmp/$p.log | grep -a "Client does not have the requested scope" | grep -aoE "scope '[^']{0,40}" | head -3; done
} 2>&1 | tee $OUT


cat $OUT
rm /tmp/ing.log /tmp/sos-*.log
