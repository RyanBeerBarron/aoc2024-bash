source ../common.bash
LOG_LEVEL="$LOG_DEBUG"
INCREASING=1
DECREASING=-1

function is_safe()
{
	local nums gradient dampened diff prev cur i
	nums=($1)
	gradient=$2
	dampened=$3
	((prev = nums[0]))
	for ((i = 1; i < ${#nums[@]}; i++)); do
		((cur = nums[i]))
		((diff = cur - prev))
		((diff *= gradient))
		if ((diff > 0 && diff <= 3)); then
			((prev = cur))
		else
			local code=1
			if test "$dampened" = "false"; then
				is_safe "${nums[*]:0:i} ${nums[*]:i+1}" "$gradient" "true" \
					|| is_safe "${nums[*]:0:i-1} ${nums[*]:i}" "$gradient" "true"
				code="$?"
			fi
			return "$code"
		fi
	done
	return 0
}

((safe=0, line_count=1))
while read line; do
	if is_safe "$line" "$INCREASING" "false" || is_safe "$line" "$DECREASING" "false";
		then log_debug "line $line_count is safe"; ((safe++))
		else log_debug "line $line_count is not safe"
	fi
	((line_count++))
done
echo $safe
