source ../common.bash

: ${LOG_LEVEL:=$LOG_INFO}
IFS=,

case "$1" in
part1) reply=score ;;
part2) reply=tiles ;;
esac

function move-forward ()
{
	case "$direction" in
	east) ((x++)) ;;
	west) ((x--)) ;;
	north) ((y--)) ;;
	south) ((y++)) ;;
	esac
}

function turn-clockwise ()
{
	case "$direction" in
	east) echo south ;;
	south) echo west ;;
	west) echo north ;;
	north) echo east ;;
	esac
}

function turn-counter-clockwise ()
{
	case "$direction" in
	east) echo north ;;
	north) echo west ;;
	west) echo south ;;
	south) echo east ;;
	esac
}

function print-queue ()
{
	local i
	printf -v out '\n'
	for ((i=0; i<${#priority_q[@]}; i++)); do
		printf -v out '%sNode %d: %s\n' "$out" "$i" "${priority_q[i]}"
	done

}

function explore-forward ()
{
	local x="$1" y="$2" direction="$3" score="$4" path="$5"
	move-forward
	local key="$x,$y"
	path="$path,$x:$y"
	c=${grid[$key]}
	if test "$c" = "#"; then return 0; fi
	((score++))
	local best_score
	best_score=${cache["$key,$direction"]}
	if test -n "$best_score" && ((score > best_score)); then return 0; fi
	if test -n "$best_score" && ((score == best_score)); then
		combine
		return 0
	fi
	cache["$key,$direction"]=$score
	enqueue
}

function combine ()
{
	for ((i=start_q; i<end_q; i++)); do
		node=${priority_q[i]}
		read node_x node_y node_dir node_score node_path <<<"$node"
		if ((x == node_x && y == node_y)) && test "$direction" = "$node_dir"; then
			log_debug "Combining $path and $node_path"
			local -A set=()
			set -- $path $node_path
			for p; do
				set[$p]=1
			done
			node="$x,$y,$direction,$score,${!set[*]}"
			priority_q[i]="$node"
			return 0
		fi
	done
}

function enqueue ()
{
	local added="false" i ele
	ele="$x,$y,$direction,$score,$path"
	for ((i=start_q; i<end_q; i++)); do
		node=${priority_q[i]}
		read node_x node_y node_dir node_score node_path <<<"$node"
		if ((score <= node_score)); then
			added="true"
			priority_q=("${priority_q[@]:0:i}" "$ele" "${priority_q[@]:i}")
			((end_q++))
			break
		fi
	done
	if test "$added" = "false"; then
		priority_q[end_q]="$ele"
		((end_q++))
	fi
	log_debug "Added node=$ele at position $((i-start_q))"
}

function explore ()
{
	local key c cache_key current_best node
	local x y direction score
	node=${priority_q[start_q]}
	((start_q++))
	read x y direction score path <<<"$node"

	key="$x,$y"
	c=${grid[$key]}
	log_info "Popped node $x,$y facing $direction with score $score"
	if (( x == end_x && y == end_y )); then
		result="$score"
		return 1
	fi

	explore-forward "$x" "$y" "$direction" "$score" "$path"
	explore-forward "$x" "$y" "$(turn-clockwise)" "$((score+1000))" "$path"
	explore-forward "$x" "$y" "$(turn-counter-clockwise)" $((score+1000)) "$path"
	priority_q=("${priority_q[@]:start_q:end_q}")
	((start_q=0, end_q=${#priority_q[@]}))
}


declare -A grid=()
((height=0))
while read line; do
	width=${#line}
	for ((x=0; x<width; x++)); do
		key="$x,$height"
		c=${line:x:1}
		if test "$c" = "S"; then
			start_x="$x"
			start_y="$height"
		fi
		if test "$c" = "E"; then
			end_x="$x"
			end_y="$height"
		fi
		grid[$key]="$c"
	done
	((height++))
done

x="$start_x"
y="$start_y"
direction="east"
score=0
best_score=-1
declare -A cache=()
declare -a priority_q=()
priority_q+=("$x,$y,$direction,$score,$x:$y")
cache["$x,$y,$direction"]="$score"
start_q=0
end_q=1
log_info "start pos=$x,$y. end pos=$end_x,$end_y"

while explore; do
	if (( LOG_LEVEL >= LOG_TRACE)); then
		print-queue
		log_trace "$out"
	fi
done

log_info "queue has size=${#priority_q[@]}"
print-queue
log_info "$out"
declare -A set=()
for node in "${priority_q[@]}"; do
	read x y direction score path <<<"$node"
	if ((score > result)); then break; fi
	if (( x == end_x && y == end_y)); then
		((best_path++));
		set -- $path
		for node; do
			set["$node"]="1"
		done
	fi
done
log_info "got $best_path paths with score $result"
log_info "got ${#set[@]} best tile"
log_trace "bes tiles: ${!set[*]}"
case "$reply" in
score) echo "$result" ;;
tiles) echo "${#set[@]}" ;;
esac
