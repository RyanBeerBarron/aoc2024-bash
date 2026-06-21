# To try every operator, could build a 2d matrice. instead of whatever im doing now
#
# Load entire file in memory.
# Sort each row by how hard to compute, from hardest to easiest, then start each thread, each skipping 'n core' rows each iteration
#
# Test if there is at least one combination of operators
# for 'base' and 'numbers' list that will compute to 'total'

source ../common.bash

function get_operator ()
{
	local pow2_j=1 i="$1" j="$2" bitwise_and
	(( pow2_j = 1 << j ))
	(( bitwise_and = i & pow2_j ))
	log_debug "i=$i, j=$j, pow2_j=$pow2_j, bitwise_and=$bitwise_and"
	case "$bitwise_and" in
	0) echo "add" ;;
	*) echo "multiply" ;;
	esac
}

function check_sum ()
{
	local size max_combination total_check num operator
	local i j
	size=${#numbers[@]}
	(( max_combination = 1 << size ))
	for ((i=0; i<max_combination; i++)); do
		total_check="$base"
		for((j=0; j<size; j++)); do
			num=${numbers[j]}
			op=$(get_operator "$i" "$j")
			case "$op" in
			add) ((total_check += num)) ;;
			multiply) ((total_check *= num)) ;;
			esac
		done
		if (( total == total_check )); then
			return 0
		fi
	done
	log_debug "size=$size, max_combination=$max_combination"
	return 1
}

let result=0
let line_count=0
while read line; do
	let line_count++
	set -- $line
	total="${1%:}"
	base="$2"
	shift 2
	numbers=()
	for num; do numbers+=("$num"); done
	log_debug "total=$total, base=$base, numbers=${numbers[@]}"
	numbers_count=${#numbers[@]}
	(( cardinality = numbers_count * ( 1 << numbers_count) ))
	log_info "line number=$line_count cardinality=$cardinality"
	if check_sum; then
		(( result += total))
	fi
	# exit 0
done
echo "result=$result"
