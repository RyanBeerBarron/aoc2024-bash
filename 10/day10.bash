source ../common.bash

: ${LOG_LEVEL:="$LOG_TRACE"}

declare -a trailheads=()

function save_trailheads ()
{
	if ((cell == 0)); then
		log_debug "saving trailhead $i:$j"
		trailheads+=("$i:$j")
	fi
}

function explore_trailhead ()
{
	local trailhead i j orig_i orig_j total
	local -A explored_steps=()
	for ((n="$pid"; n<${#trailheads[@]}; n+=cores)); do
		trailhead=${trailheads[n]}
		i=${trailhead%:*}
		j=${trailhead#*:}
		orig_i="$i" orig_j="$j"
		explored_steps=()
		log_info "starting search at trailhead ($i,$j)"
		((total_snapshot = total))
		search_trail $((i+1)) "$j" 0
		search_trail $((i-1)) "$j" 0
		search_trail "$i" $((j+1)) 0
		search_trail "$i" $((j-1)) 0
		((diff = total - total_snapshot))
		log_info "found $diff perfect trail from trailhead ($i,$j)"
	done
	echo "$total" >&"$result_fd"
}

function search_trail ()
{
	local i="$1" j="$2" prevcell="$3" cell
	local coord="$i:$j"
	local cur_total diff
	if test "${explored_steps[$coord]}" = "1" && test "$method" = "score"; then
		return
	fi
	get_cell || return

	if ((cell != prevcell + 1)); then
		return
	fi
	explored_steps[$coord]=1
	if ((cell == 9)); then
		log_debug "Found perfect trail from ($orig_i,$orig_j) to ($i,$j)"
		((total++))
		return
	fi

	cur_total="$total"
	search_trail $((i+1)) "$j" "$cell"
	search_trail $((i-1)) "$j" "$cell"
	search_trail "$i" $((j+1)) "$cell"
	search_trail "$i" $((j-1)) "$cell"
	((diff = total - cur_total))
}

case "$1" in
part1) method="score";;
part2) method="rate" ;;
*) echo "invalid first argument=$1" >&2; exit 1; ;;
esac

build_matrix
for_each_cell "save_trailheads"

((total=0))

result_file=$(mktemp)
exec {result_fd}>"$result_file"
run_in_parallel "explore_trailhead"
wait
exec {result_fd}>&-
exec {result_fd}<"$result_file"
while read -u "$result_fd" subresult; do
	((total+=subresult))
done

echo "$total"
