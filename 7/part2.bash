# Instead of using recursion to generate every matrix and trying all of them, which is slow
# I saw online to directly use recursion at each step.
#   to solve 10: 2 3 5
#       you do      '2+3=5' '10-5=5', now try to solve:      5: 5
#       and you do  '2*3=6' '10-6=4', now try to solve:  4: 5
# And with guards to stop as soon as the running total is greater than the target, it completely cuts entire subtree of the recursion
# and as soon as one recursion leaf node has a total equal to the target, also short circuit the entire function and return
#
# This makes it run quite fast (around 25 seconds on 16 cores)

# Globals
LOG_LEVEL=3
defaultIFS="$IFS"
((total=0))
((cores=$(nproc)))
results=(0 0 0)

exec {stdout}>&1


# Inside matrix, each element is a string with each character representing an operation
# 0 -> '+'
# 1 -> '*'
# 2 -> '||' (concatenation)
# It contains all the permutations that will be needed
pattern='{0,1,2}'
function build_matrix ()
{
	local count="$1"
	for ((i=0; i<count; i++)); do
		str="$str$pattern"
	done
	matrix=( $(eval "echo $str") )
}


function log ()
{
	local required_level="$1"
	shift
	if (( LOG_LEVEL >= required_level)); then datetime=$(date "+%FT%T"); echo "[$datetime] $@" >&"$stdout"; fi
}

function fatal ()
{
	log 0 "@"
	exit 1
}
function error ()
{
	log 1 "@"

}
function warn ()
{
	log 2 "@"

}
function info ()
{
	log 3 "$@"
}

function debug ()
{
	log 4 "$@"
}

function trace ()
{
	log 5 "@"
}

function get_operator ()
{
	local pow2_j=1 i="$1" j="$2" bitwise_and
	(( pow2_j = 1 << j ))
	(( bitwise_and = i & pow2_j ))
	debug "i=$i, j=$j, pow2_j=$pow2_j, bitwise_and=$bitwise_and"
	case "$bitwise_and" in
	0) echo "add" ;;
	*) echo "multiply" ;;
	esac
}

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

function worker ()
{
	local pid="$1" total target base size
	declare -a numbers
	((total=0))
	for (( i="$pid"; i < "${#file[@]}"; i+=cores)); do
		line="${file[i]}"
		set -- $line
		target="${1%:*}"
		base="$2"
		info "process $pid: on line $i, checking target=$target"
		shift 2
		numbers=()
		for num; do numbers+=("$num"); done
		size="${#numbers[@]}"
		check_sum "$target" "$base" 0;
		return_code=$?
		if (( return_code == 0)); then
			debug "process $pid: adding target=$target to total=$total, new total=$((total + target))";
			(( total += target ));
		fi
		info "process $pid: done with line $i, return code=$return_code"
	done
	info "process $pid: Done, total=$total"
	echo "$total" >&"$result_fd"
}

read -rd '' file
debug "read file"
exec {stream_file}<<<"$file"
file=()
while read -u "$stream_file" line; do set -- $line; file+=("$#: $*"); done
debug "built array with number of args"
IFS=$'\n'; file="${file[*]}"; IFS="$defaultIFS"
debug "joined array"
file=$(sort --field-separator ':' -k 1gr,1gr <<<"$file")
debug "sorted file from hardest to easiest"
(( line_count=0 ))
exec {stream_file}<<<"$file"
# array that holds all the row that each subprocess will work on
file=()
while read -u "$stream_file" line; do
	((line_count++))
	line="${line#*: }"
	file+=("$line")
done
debug "final array in order built"

result_file=$(mktemp)
exec {result_fd}>"$result_file"
for ((i=0; i<cores; i++)); do
	(worker "$i") &
done
wait
exec {result_fd}>&-
exec {result_fd}<"$result_file"
while read -u "$result_fd" subresult; do
	((total += subresult))
done
echo "total=$total"
