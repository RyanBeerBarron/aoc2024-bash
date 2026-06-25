source ../common.bash

LOG_LEVEL="$LOG_DEBUG"

declare -A antenna_kind=()
declare -A antinodes=()

PART="$1"

build_map

function save_antenna_position ()
{
	if test "$cell" = "."; then return; fi
	log_debug "Found antenna $cell at pos($i,$j)"
	antenna_kind[$cell]="1"
	local -n bucket="antenna_$cell"
	bucket+=("$i:$j")
}

function print_bucket ()
{
	local -n bucket="antenna_$1"
	echo "${bucket[@]}"
}

function all_pairs ()
{
	local n m;
	local atn1 atn2;
	for ((n=0; n<${#coordinates[@]}-1; n++)); do
		for ((m = n+1; m < ${#coordinates[@]}; m++)); do
			atn1="${coordinates[n]}"
			atn2="${coordinates[m]}"
			log_debug "Antenna pair: atn1=$atn1, atn2=$atn2"
			case "$PART" in
			part1) find_antinode_part1 ;;
			part2) find_antinode_part2 ;;
			esac
		done
	done
}

function find_antinode_part1 ()
{
	local atn1_i=${atn1%:*} atn1_j=${atn1#*:}
	local atn2_i=${atn2%:*} atn2_j=${atn2#*:}
	local delta_i delta_j

	local anode1_i anode1_j
	local anode2_i anode2_j
	# We compute the vector to go from atn1 -> atn2
	# To find the two antinode:
	#   - we start at atn1 and go backwards => substract the delta on atn1
	#   - we start at atn2 and go forward   => add the delta to atn2
	(( delta_i = atn2_i - atn1_i ))
	(( delta_j = atn2_j - atn1_j ))

	(( anode1_i = atn1_i - delta_i ))
	(( anode1_j = atn1_j - delta_j ))
	i="$anode1_i"
	j="$anode1_j"
	if get_cell; then
		save_antinode
	fi

	(( anode2_i = atn2_i + delta_i ))
	(( anode2_j = atn2_j + delta_j ))
	i="$anode2_i"
	j="$anode2_j"
	if get_cell; then
		save_antinode
	fi

	log_trace \
		"For atn1=$atn1 atn2=$atn2 and d_i=$delta_i d_j=$delta_j: " \
		"anode1($anode1_i,$anode1_j) and " \
		"anode2($anode2_i,$anode2_j)"

}

function find_antinode_part2 ()
{
	local atn1_i=${atn1%:*} atn1_j=${atn1#*:}
	local atn2_i=${atn2%:*} atn2_j=${atn2#*:}
	local delta_i delta_j

	# We compute the vector to go from atn1 -> atn2
	# To find the two antinode:
	#   - we start at atn1 and go backwards => substract the delta on atn1
	#   - we start at atn2 and go forward   => add the delta to atn2
	(( delta_i = atn2_i - atn1_i ))
	(( delta_j = atn2_j - atn1_j ))

	i="$atn1_i"
	j="$atn1_j"
	while get_cell; do
		save_antinode
		(( i -= delta_i ))
		(( j -= delta_j ))
	done

	i="$atn2_i"
	j="$atn2_j"
	while get_cell; do
		save_antinode
		(( i += delta_i ))
		(( j += delta_j ))
	done
}

function save_antinode ()
{
	antinodes["$i:$j"]='1'
}

for_each_cell "save_antenna_position"

log_info "All antenna types: ${!antenna_kind[@]}"
for key in "${!antenna_kind[@]}"; do
	log_info "Antennas of type $key: $(print_bucket $key)"
done

for key in "${!antenna_kind[@]}"; do
	declare -gn coordinates="antenna_$key"
	log_debug "Doing every pair of antenna $key"
	all_pairs
done

echo "${#antinodes[@]}"
