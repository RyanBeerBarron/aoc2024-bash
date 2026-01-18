INCREASING=1
DECREASING=0

function within_bounds()
{
	if ((gradient == INCREASING)); then
		((diff > 0 && diff <= 3))
	else
		((diff < 0 && diff >= -3))
	fi
}

function is_safe()
{
	local nums gradient diff prev cur i
	nums=($1)
	gradient=$2
	((prev = nums[0]))
	for ((i = 1; i < ${#nums[@]}; i++)); do
		((cur = nums[i]))
		((diff = cur - prev))
		if within_bounds; then
			((prev = cur))
		else
			return 1
		fi
	done
	return 0
}

let safe=0
while read line; do
	if is_safe "$line" "$INCREASING" || is_safe "$line" "$DECREASING"; then
		((safe++))
	fi
done
echo $safe
