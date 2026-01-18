within_bounds()
{
	# 1 if increasing, 0 otherwise
	local diff="$1" increasing="$2"
	if ((increasing)); then
		((diff > 0 && diff <= 3))
	else
		((diff < 0 && diff >= -3))
	fi
}

is_safe()
{
	local nums increasing dampened diff prev cur i
	nums=($1)
	increasing=$2
	dampened=$3
	((prev = nums[0]))
	for ((i = 1; i < ${#nums[@]}; i++)); do
		((cur = nums[i]))
		((diff = cur - prev))
		if within_bounds "$diff" "$increasing"; then
			((prev = cur))
		else
			if ! ((dampened)); then
				is_safe "${nums[*]:0:i} ${nums[*]:i+1}" "$increasing" 1 \
					|| is_safe "${nums[*]:0:i-1} ${nums[*]:i}" "$increasing" 1
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
