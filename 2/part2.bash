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
	local nums gradient dampened diff prev cur i
	nums=($1)
	gradient=$2
	dampened=$3
	((prev = nums[0]))
	for ((i = 1; i < ${#nums[@]}; i++)); do
		((cur = nums[i]))
		((diff = cur - prev))
		if within_bounds; then
			((prev = cur))
		else
			if ! ((dampened)); then
				is_safe "${nums[*]:0:i} ${nums[*]:i+1}" "$gradient" 1 \
					|| is_safe "${nums[*]:0:i-1} ${nums[*]:i}" "$gradient" 1
				return $?
			else
				return 1
			fi
		fi
	done
	return 0
}

let safe=0
while read line; do
	if is_safe "$line" 1 0 || is_safe "$line" 0 0; then
		((safe++))
	fi
done
echo $safe
