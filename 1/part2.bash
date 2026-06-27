source ../common.bash
: ${LOG_LEVEL:="$LOG_TRACE"}
declare -A count=()
read -rd '' file

while read ignored second; do
	((count[$second]++))
done <<<"$file"

if ((LOG_LEVEL == LOG_TRACE)); then
	for key in "${!count[@]}"; do
		val="${count[$key]}"
		log_trace "count[$key]=$val"
	done
fi

((total = 0))
while read first second; do
	log_trace \
		"total=$total," \
		"first=$first," \
		"count[first]=${count[$first]:-0}," \
		"first*count=$((first * count[$first]))"
	((total += first * count[$first]))
done <<<"$file"
echo "$total"
