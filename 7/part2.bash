# Instead of using recursion to generate every matrix and trying all of them, which is slow
# I saw online to directly use recursion at each step.
#   to solve 10: 2 3 5
#       you do      '2+3=5' '10-5=5', now try to solve:      5: 5
#       and you do  '2*3=6' '10-6=4', now try to solve:  4: 5
# And with guards to stop as soon as the running total is greater than the target, it completely cuts entire subtree of the recursion
# and as soon as one recursion leaf node has a total equal to the target, also short circuit the entire function and return
#
# This makes it run quite fast (around 25 seconds on 16 cores)

source ../common.bash

# Globals
LOG_LEVEL="$LOG_INFO"
defaultIFS="$IFS"
total=0
cores=$(nproc)

function check_sum ()
{
	local target="$1" total="$2" i="$3"
	if ((i >= size)); then
		(( target == total ))
		return
	fi
	if ((total > target)); then return 1; fi
	local num="${numbers[i]}"
	check_sum "$target" $(( total + num )) $((i+1)) && return 0
	check_sum "$target" $(( total * num )) $((i+1)) && return 0
	check_sum "$target" "${total}${num}" $((i+1)) && return 0
	return 1
}

function process_equations ()
{
	local total=0 target base size
	declare -a numbers
	for (( i="$pid"; i < "${#file[@]}"; i+=cores)); do
		line="${file[i]}"
		set -- $line
		target="${1%:*}"
		base="$2"
		log_info "on line $i, checking target=$target"
		shift 2
		numbers=()
		for num; do numbers+=("$num"); done
		size="${#numbers[@]}"
		check_sum "$target" "$base" 0;
		return_code=$?
		if (( return_code == 0)); then
			log_debug "adding target=$target to total=$total, new total=$((total + target))";
			(( total += target ));
		fi
		log_info "done with line $i, return code=$return_code"
	done
	log_info "Done, total=$total"
	echo "$total" >&"$result_fd"
}

exec {add_length_fd}< <(while read line; do set -- $line; echo "$#: $*"; done)
exec {sort_length_fd}< <(sort --field-separator ':' -k 1gr,1gr <&"$add_length_fd")
exec {final_file_fd}< <(while read -u "$sort_length_fd" line; do echo "${line#*: }"; done)
(( line_count=0 ))
file=()
while read -u "$final_file_fd" line; do
	((line_count++))
	file+=("$line")
done
log_debug "final array, in order, built. Total lines=$line_count"

result_file=$(mktemp)
exec {result_fd}>"$result_file"
run_in_parallel process_equations
wait
exec {result_fd}>&-
exec {result_fd}<"$result_file"
while read -u "$result_fd" subresult; do
	((total += subresult))
done
echo "total=$total"
