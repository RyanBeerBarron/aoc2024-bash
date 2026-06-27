
# Swap two element in an array
# @param $1 Array variable name
# @param $2 Index of first element
# @param $3 Index of second element
# @return   0 if swap succeeded
#           1 if an index is out of bounds
function swap ()
{
	local -n array="$1"
	local i="$2" j="$3"
	if (( i < 0 || j < 0 || i >= ${#array[@]} || j >= ${#array[@]} )); then
		return 1
	fi
	local left="${array[i]}" right="${array[j]}"
	log_trace "swapping array[$i]=$left with array[$j]=$right"
	array[i]="$right"
	array[j]="$left"
	return 0
}
