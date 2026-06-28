source ../common.bash
shopt -s extglob
: ${LOG_LEVEL:=$LOG_DEBUG}

case "$1" in
part1) blink_total=25 ;;
part2) blink_total=75 ;;
*) echo "Invalid argument $1" >&2; exit 1 ;;
esac

read -d '' line
set -- $line


declare -A stone_freq=()
for stone; do
	((stone_freq[$stone]++))
done

function count_total_stones ()
{
	((total=0))
	for frequency in "${stone_freq[@]}"; do
		((total+=frequency));
	done
}

log_debug "frequency map of stones: ${stone_freq[@]@A}"
for ((blink = 0; blink < blink_total; blink++)); do
	declare -A new_freq=()
	for stone in "${!stone_freq[@]}"; do
		freq="${stone_freq[$stone]}"
		if (( stone == 0 )); then
			(( new_freq[1] += freq ))
			continue;
		fi

		if (( ${#stone} % 2 == 0)); then
			((half_length = ${#stone} / 2))
			firsthalf=${stone:0:half_length}
			secondhalf=${stone:half_length}
			# remove leading 0s, and convert to 0 if empty string
			secondhalf=${secondhalf##+(0)}; secondhalf=${secondhalf:-0}
			(( new_freq[$firsthalf] += freq ))
			(( new_freq[$secondhalf] += freq ))
			continue
		fi

		((stone *= 2024))
		(( new_freq[$stone] += freq ))
	done
	copy_map "new_freq" "stone_freq"
	log_debug "frequency map of stones: ${stone_freq[@]@A}"
	count_total_stones
	log_info "at blink $blink, got $total stones"
done
echo "$total"
