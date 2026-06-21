source ../common.bash
LOG_LEVEL="$LOG_INFO"
INCREASING=1
DECREASING=-1

function is_safe()
{
	local nums gradient diff prev cur i
	nums=($1)
	gradient="$2"
	((prev = nums[0]))
	for ((i = 1; i < ${#nums[@]}; i++)); do
		((cur = nums[i]))
		((diff = cur - prev))
		((diff *= gradient)) # in the 'decreasing' case, multiply by -1 avoids an if/else
		if ((diff > 0 && diff <= 3)); then
			((prev = cur))
		else
			log_debug "line $line_count is not safe"
			return 1
		fi
	done
	log_debug "line $line_count is safe"
	return 0
}

((safe=0, line_count=1))
while read line; do
	if is_safe "$line" "$INCREASING" || is_safe "$line" "$DECREASING"; then
		((safe++))
	fi
	((line_count++))
done
echo "$safe"
