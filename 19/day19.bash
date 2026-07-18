source ../common.bash

: ${LOG_LEVEL:=$LOG_DEBUG}

case "$1" in
part1) part=1 ;;
part2) part=2 ;;
esac

# part 1 function
function is-design-possible ()
{
	local pattern="$1" solution=""
	log_info "Testing pattern $pattern"
	if make-design "$pattern"; then
		log_info "Pattern $pattern can be made with $solution"
		((result++))
	else
		log_info "Pattern $pattern is impossible"
	fi
}

# part 2 function
function count-all-solutions ()
{
	local pattern="$1" solution="" count=0
	log_info "Counting solutions for pattern '$pattern'"
	find-design "$pattern"
	log_info "Pattern '$pattern' has $out solutions"
	((result += out))
}

function make-design ()
{
	local design="$1" new_design i
	if test -z "$design"; then return 0; fi
	for ((i=longest_towel; i>0; i--)); do
		local key=${design:0:i}
		if test "${towel_set[$key]}" = "1"; then
			new_design="${design:i}"
			log_trace "Found prefix $key for design $design, next design '$new_design'"
			solution="$solution $key"
			if make-design "$new_design"; then return 0; fi
			log_trace "Current breakdown does not work. Starting again"
			solution=${solution% $key}
		fi
	done
	return 1
}

function find-design ()
{
	local design="$1" new_design i
	local count=0
	for ((i=longest_towel; i>0; i--)); do
		if (( i > ${#design} )); then continue; fi
		local key="${design:0:i}"
		if test "${towel_set[$key]}" = "1"; then
			new_design="${design:i}"
			log_trace "Found prefix '$key' for design '$design', next design '$new_design'. (i=$i, count=$count)"
			solution="$solution $key"
			if test -z "$new_design"; then
				((count++))
				log_debug "Pattern '$pattern' can be made with '$solution'"
			elif test -n "${cache[$new_design]}"; then
				value=${cache[$new_design]};
				log_debug "Design '$new_design' already computed. It has $value solutions"
				log_debug "Pattern '$pattern' can be made with '$solution $new_design'"
				((count += value))
			else
				find-design "$new_design"
				((count += out))
			fi
			solution=${solution% $key}
		fi
	done
	cache[$design]="$count"
	out=$count
	log_debug "Design '$design' has $out solutions"
	return
}

IFS=', '
read towels
# there are no duplicates in the input. So a set can be used.
declare -A towel_set=()
declare -A cache=()
longest_towel=-1
for towel in $towels; do
	if (( ${#towel} > longest_towel )); then
		longest_towel=${#towel}
	fi
	towel_set[$towel]=1
done

log_info "Have ${#towel_set[@]} towels total. Longest towel is $longest_towel stripes long"
for key in ${!towel_set[@]}; do
	log_debug "Available towel: $key"
done
read empty
mapfile -t patterns

((result=0))
for pattern in "${patterns[@]}"; do
	case "$part" in
	1) is-design-possible "$pattern";;
	2) count-all-solutions "$pattern" ;;
	esac
	printf '\n'
done
echo "$result"
