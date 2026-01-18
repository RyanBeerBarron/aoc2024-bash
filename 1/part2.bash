declare -A count=()
mapfile MAP

exec 3< <(printf '%s' "${MAP[@]}")
while read -u 3 first second; do
	((count[$second]++))
done

((total = 0))
exec 3< <(printf '%s' "${MAP[@]}")
while read -u 3 first second; do
	((total += first * count[$first]))
done
echo "$total"
