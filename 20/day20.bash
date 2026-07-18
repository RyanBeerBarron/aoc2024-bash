source ../common.bash

: ${LOG_LEVEL:=$LOG_DEBUG}
IFS=,

case "$1" in
part1) radius=2; ;;
part2) radius=20 ;;
esac

function set-direction ()
{
	local x="$x" y="$y"
	down="$x,$((y+1))"
	up="$x,$((y-1))"
	right="$((x+1)),$y"
	left="$((x-1)),$y"

	if      test "${grid[$up]}"    != "#";  then direction=up
	elif    test "${grid[$down]}"  != "#";  then direction=down
	elif    test "${grid[$right]}" != "#";  then direction=right
	elif    test "${grid[$left]}"  != "#";  then direction=left; fi

	log_info "Direction=$direction"
}

function move ()
{
	new_x="$x" new_y="$y" new_direction="$direction"
	case "$1" in
	left) new_direction=$(turn-left  "$direction") ;;
	right) new_direction=$(turn-right  "$direction") ;;
	esac
	case "$new_direction" in
	up) ((new_y--));;
	down) ((new_y++));;
	left) ((new_x--));;
	right) ((new_x++));;
	esac
	new_pos="$new_x,$new_y"
	if test "${grid[$new_pos]}" != "#"; then
		log_trace "Move $1"
		return 0
	else
		log_trace "Cant move $1"
		return 1
	fi
}

function update-pos ()
{
	log_trace "x=$x new_x=$new_x y=$y new_y=$new_y direction=$direction new_direction=$new_direction"
	x="$new_x"
	y="$new_y"
	direction="$new_direction"
}

function turn-right ()
{
	case "$1" in
	up)     echo right ;;
	right)  echo down ;;
	down)   echo left ;;
	left)   echo up ;;
	esac
}

function turn-left ()
{
	case "$1" in
	up)     echo left ;;
	left)   echo down ;;
	down)   echo right ;;
	right)  echo up ;;
	esac
}

function find-shortcuts ()
{
	local pos="$1"
	set -- $pos
	x="$1"
	y="$2"
	log_info "Checking shortcuts starting from $pos ($i/$step)"
	local -a points=()
	local i j
	for ((i=x-radius; i <= x+radius; i++)); do
		for ((j=y-radius; j <= y+radius; j++)); do
			if (( i < 0 || i >= width || j < 0 || j >= height)); then continue ; fi
			(( d_x = x - i >= 0 ? x - i : i - x ))
			(( d_y = y - j >= 0 ? y - j : j - y ))
			((distance = d_x + d_y))
			if (( distance > radius )); then continue; fi
			check-shortcut "$i,$j"
		done
	done
}

function check-shortcut ()
{
	local endpos="$1"
	if test "${grid[$endpos]}" != "#"; then
		start=${time[$pos]}
		end=${time[$endpos]}
		(( time_save = end - (start+distance) ))
		if (( time_save >= 100 )); then
			((sum++))
			log_debug "Found shortcut from $pos, to $endpos. Saving $time_save picoseconds"
		fi
	fi
}
declare -A grid=()
((height=0))
while read line; do
	width=${#line}
	for ((x=0; x<width; x++)); do
		key="$x,$height"
		c=${line:x:1}
		case "$c" in
		S)
			start_x="$x"
			start_y="$height"
			log_info "Start pos=$start_x,$start_y"
			;;
		E)
			end_pos="$x,$height"
			end_x="$x"
			end_y="$height"
			log_info "End pos=$end_pos"
			;;
		esac
		grid[$key]="$c"
	done
	((height++))
done

declare -a track=()
declare -A time=()

step=0
x="$start_x"
y="$start_y"
pos="$x,$y"
set-direction
while test "$pos" != "$end_pos"; do
	pos="$x,$y"
	track+=("$pos")
	time[$pos]="$step"
	((step++))
	if move foward;     then update-pos
	elif move left;     then update-pos
	elif move right;    then update-pos; fi
done

log_info "racetrack is $step steps long"
sum-in-parallel 'find-shortcuts' 'track'
echo "$total"
