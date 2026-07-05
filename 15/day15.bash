source ../common.bash

: ${LOG_LEVEL:="$LOG_TRACE"}

case "$1" in
part1)
	part="part1"
	build_grid=part1-build-grid
	move_robot=part1-move-robot
	sum_coords=part1-sum-coordinates
	;;
part2)
	part="part2"
	build_grid=part2-build-grid
	move_robot=part2-move-robot
	sum_coords=part2-sum-coordinates
	;;
esac

# common functions
function print-grid ()
{
	local x y key grid_str='\n'
	for ((y=0; y<height; y++)); do
		for ((x=0; x<width; x++)); do
			key="$x,$y"
			printf -v grid_str '%s%c' "$grid_str" "${grid[$key]}"
		done
		printf -v grid_str '%s\n' "$grid_str"
	done
	echo "$grid_str"
}

function move ()
{
	local direction="$1"
	case "$direction" in
	'<') ((x--));;
	'>') ((x++));;
	'^') ((y--));;
	'v') ((y++));;
	esac
}

# @params $@ list of keys to be shifted
function shift-items ()
{
	local key tmp c first_key
	first_key="$1"
	c=${grid[$1]}
	shift
	for key; do
		tmp=${grid[$key]}
		grid[$key]="$c"
		c="$tmp"
	done
	grid[$first_key]="$c"
}

function update-robot-pos ()
{
	local direction="$1"
	case "$direction" in
	'<') ((robot_x--));;
	'>') ((robot_x++));;
	'^') ((robot_y--));;
	'v') ((robot_y++));;
	esac
}

# part 1 functions
function part1-build-grid ()
{
	if test "$c" = "@"; then
		robot_x="$x"
		robot_y="$height"
	fi
	grid[$key]=$c
	((x++))
}

function part1-move-robot ()
{
	keys=()
	x="$robot_x"
	y="$robot_y"
	keys+=("$x,$y")
	while true; do
		move "$direction"
		key="$x,$y"
		c=${grid[$key]}
		case "$c" in
		'#')
			break
			;;
		'O')
			keys+=($key)
			;;
		'.')
			# add key and shift and update robot position
			keys+=($key)
			shift-items "${keys[@]}"
			update-robot-pos "$direction"
			break
			;;
		esac
	done
}

function part1-sum-coordinates ()
{
	local x y key c
	for ((y=0; y<height; y++)); do
		for ((x=0; x<width; x++)); do
			key="$x,$y"
			c=${grid[$key]}
			if test "$c" = "O"; then
				((total += x + y*100))
			fi
		done
	done
}

# part 2 functions
function push ()
{
	local key="$1"
	stack+=("$key")
	((stack_ptr++))
	log_trace "pushed key=$key in stack"
	log_trace "stack=${stack[@]}"
}

# @var[out] key
# @var[out] x
# @var[out] y
function dequeue ()
{
	key=${stack[queue_start++]}
	x=${key%,*}
	y=${key#*,}
}

function pop ()
{
	key=${stack[--stack_ptr]}
	log_trace "pop $key at $stack_ptr"
	x=${key%,*}
	y=${key#*,}
}

function move-robot ()
{
	local direction="$1"
	orig="$robot_x,$robot_y"
	update-robot-pos "$direction"
	dest="$robot_x,$robot_y"
	tmp=${grid[$orig]}
	grid[$orig]=${grid[$dest]}
	grid[$dest]=$tmp
}

function part2-build-grid ()
{
	case "$c" in
	'#') next_c='#' ;;
	'O') c='['; next_c=']' ;;
	'.') next_c='.' ;;
	'@')
		robot_x="$x"
		robot_y="$height"
		next_c='.' ;;
	esac
	grid[$x,$height]=$c
	((x++))
	grid[$x,$height]=$next_c
	((x++))
}

function part2-move-robot ()
{
	case "$direction" in
	'^'|'v') move-robot-vertical || log_debug "Encountered a '#'. Not movement" ;;
	'<'|'>') move-robot-horizontal ;;
	esac
}

function move-robot-horizontal ()
{
	keys=()
	x="$robot_x"
	y="$robot_y"
	keys+=("$x,$y")
	while true; do
		move "$direction"
		key="$x,$y"
		c=${grid[$key]}
		case "$c" in
		'#')
			break
			;;
		'['|']')
			keys+=($key)
			;;
		'.')
			# add key and shift and update robot position
			keys+=($key)
			shift-items "${keys[@]}"
			update-robot-pos "$direction"
			break
			;;
		esac
	done
}

function move-robot-vertical ()
{
	log_trace "vertical move: $direction"
	x="$robot_x"
	y="$robot_y"
	local -A seen=()
	local -a stack=()
	queue_start=0
	stack_ptr=0

	# initialize stack once for the robot case
	# the robot can only push one block
	# blocks can push two blocks
	move "$direction"
	switch-c || return 1
	if test "$c" = '.'; then
		move-robot "$direction"
		return 0
	fi

	while ((queue_start < stack_ptr)); do
		dequeue
		move "$direction"
		switch-c || return 1
		((x++))
		switch-c || return 1
		log_trace "queue_start=$queue_start, stack_ptr=$stack_ptr"
	done

	while ((stack_ptr > 0)); do
		pop
		move-block "$direction"
	done
	move-robot "$direction"
}

function switch-c ()
{
	local key x="$x" y="$y"
	key="$x,$y"
	c=${grid[$key]}
	case "$c" in
	'#') return 1 ;;
	'[')
		if test -n "${seen[$key]}"; then return 0; fi
		push "$key"
		seen[$key]='1'
		;;
	']')
		((x--))
		key="$x,$y"
		if test -n "${seen[$key]}"; then return 0; fi
		push "$key"
		seen[$key]='1'
		;;
	esac
}

function move-block ()
{
	log_trace "moving block at $key in direction $direction"
	orig_left_key="$key"
	orig_right_key="$((x+1)),$y"
	move "$direction"
	dest_left_key="$x,$y"
	dest_right_key="$((x+1)),$y"
	log_trace "swapping key=$orig_left_key with key=$dest_left_key"
	log_trace "swapping key=$orig_right_key with key=$dest_right_key"

	tmp=${grid[$orig_left_key]}
	grid[$orig_left_key]=${grid[$dest_left_key]}
	grid[$dest_left_key]=$tmp

	tmp=${grid[$orig_right_key]}
	grid[$orig_right_key]=${grid[$dest_right_key]}
	grid[$dest_right_key]=$tmp
}

function part2-sum-coordinates ()
{
	local x y key c
	for ((y=0; y<height; y++)); do
		for ((x=0; x<width; x++)); do
			key="$x,$y"
			c=${grid[$key]}
			if test "$c" = "["; then
				((total += x + y*100))
			fi
		done
	done
}


declare -A grid=()
((height=0))
while
	read line
	test -n "$line"
do
	width=${#line}
	((x=0))
	for ((i=0; i<width; i++)); do
		key="$x,$height"
		c=${line:i:1}
		$build_grid
	done
	((height++))
done

if test "$part" = "part2"; then ((width *=2)); fi

while read -n1 direction; do
	if test -z "$direction"; then continue; fi
	log_debug "Move: $direction"
	$move_robot
	if ((LOG_LEVEL >= LOG_TRACE)); then log_trace "$(print-grid)"; fi
done

log_debug "$(print-grid)"
((total=0))
$sum_coords
echo "$total"
