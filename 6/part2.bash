shopt -s extglob

# Globals
DEBUG=0
# load file in global array
mapfile -t MAP
# Replacing all '.' square with 0 for easier checks/maths
MAP=("${MAP[@]//./0}")
MAX_Y=${#MAP[@]}
MAX_X=${#MAP[0]}

CUR_X=-1
CUR_Y=-1

NEXT_X=-1
NEXT_Y=-1

CUR=''
NEXT=''

DIRECTION=''
dx=0
dy=0

function log()
{
	((DEBUG == 0)) && return
	echo "$@"
}

function printmap()
{
	test "$DEBUG" = '0' && return
	log "============"
	log "thread $num testing obstruction at coord($x,$y):"
	local x y
	for y in "${!MAP[@]}"; do
		line=${MAP[y]}
		len=${#line}
		for ((x = 0; x < len; x++)); do
			char=${line:x:1}
			# echo "x=$x y=$y CUR_X=$CUR_X CUR_Y=$CUR_Y"
			if ((x == CUR_X && y == CUR_Y)); then
				printf '\033[44m%c\033[0m ' "$char"
			elif ((x == outer_next_x && y == outer_next_y)); then
				printf '\033[41m%c\033[0m ' "$char"
			elif ((x == NEXT_X && y == NEXT_Y)); then
				printf '\033[42m%c\033[0m ' "$char"
			elif test "$char" = '#'; then
				printf '\033[43m%c\033[0m ' "$char"
			elif [[ "$char" =~ ^[1-9a-f]+$ ]]; then
				printf '\033[7m%c\033[0m ' "$char"
			else
				printf '%c ' "$char"
			fi
		done
		printf '\n'
	done
	log "============"
}

function get_cell()
{
	local x=$1 y=$2
	line=${MAP[y]}
	echo ${line:x:1}
}

function set_cell()
{
	local x=$1 y=$2 val=$3
	line=${MAP[y]}
	set_char line $x $val
	line="${line:0:$x}${val}${line:x+1}"
	MAP[y]=$line
}

# sets a new value in 'str' (which references a variable name) at index 'index' with value 'char'
# $1(required): variable ref to 'str'
# $2(required): index
# $3(required): char
function set_char()
{
	local string=${!1}
	local index="$2"
	local char="$3"
	string="${string:0:index}${char}${string:index+1}"
	eval "$1='$string'"
}

function find_pos()
{
	for ((i = 0; i < ${#MAP[@]}; i++)); do
		local line=${MAP[i]}
		if [[ $line = *@(v|<|>|^)* ]]; then
			CUR_Y="$i"
			for ((j = 0; j < ${#line}; j++)); do
				if [[ "${line:j:1}" = @(v|<|>|^) ]]; then
					CUR_X="$j"
				fi
			done
		fi
	done
	CUR=$(get_cell "$CUR_X" "$CUR_Y")
	case "$CUR" in
	^) DIRECTION=1 ;;
	\>) DIRECTION=2 ;;
	v) DIRECTION=4 ;;
	\<) DIRECTION=8 ;;
	esac
	CUR="0"
	set_cell "$CUR_X" "$CUR_Y" "0"
}

function set_velocity()
{
	case "$DIRECTION" in
	1) dx=0 dy=-1 ;;
	2) dx=1 dy=0 ;;
	4) dx=0 dy=1 ;;
	8) dx=-1 dy=0 ;;
	esac
}

function advance()
{
	# if bitwise AND returns true, we already walked on current square with current DIRECTION
	# echo "CUR=$CUR DIRECTION=$DIRECTION"
	if ((0x${CUR} & DIRECTION)); then
		log "loop"
		return 1
	fi
	if [[ "$NEXT" =~ ^[0-9a-f]+$ ]]; then
		step
	else
		turn
	fi
	next_square
	return 0
}

function step()
{
	((CUR = 0x${CUR} | DIRECTION))
	((CUR > 9)) && CUR=$(hex $CUR)
	set_cell "$CUR_X" "$CUR_Y" $CUR
	CUR_X="$NEXT_X"
	CUR_Y="$NEXT_Y"
	CUR=$(get_cell $CUR_X $CUR_Y)
}

function turn()
{
	((CUR = 0x${CUR} | DIRECTION))
	((CUR > 9)) && CUR=$(hex $CUR)
	set_cell "$CUR_X" "$CUR_Y" $CUR
	case "$DIRECTION" in
	1) DIRECTION=2 ;; # '^' -> '>'
	2) DIRECTION=4 ;; # '>' -> 'v'
	4) DIRECTION=8 ;; # 'v' -> '<'
	8) DIRECTION=1 ;; # '<' -> '^'
	esac
	set_velocity
}

function finish()
{
	set_cell "$CUR_X" "$CUR_Y" "X"
}

function log_state()
{
	if test "$DEBUG" = '1'; then
		log "pos is: x=$CUR_X y=$CUR_Y"
		log "NEXT is: x=$NEXT_X y=$NEXT_Y"
		log "CUR=$CUR NEXT=$NEXT"
		log "DIRECTION=$(convert_direction) ($DIRECTION)"
		log "velocity is: dx=$dx dy=$dy"
	fi
}

function convert_direction()
{
	case "$DIRECTION" in
	1) echo "^" ;;
	2) echo ">" ;;
	4) echo "v" ;;
	8) echo "<" ;;
	esac
}

function in_bounds()
{
	((NEXT_X >= 0 && NEXT_X < MAX_X && NEXT_Y >= 0 && NEXT_Y < MAX_Y))
}

function hex()
{
	case "$1" in
	10) echo 'a' ;;
	11) echo 'b' ;;
	12) echo 'c' ;;
	13) echo 'd' ;;
	14) echo 'e' ;;
	15) echo 'f' ;;
	esac
}

function next_square()
{
	((NEXT_X = CUR_X + dx))
	((NEXT_Y = CUR_Y + dy))
	NEXT=$(get_cell "$NEXT_X" "$NEXT_Y")
}

function find_obstructions()
{
	# Using an array instead of an associative array to preserve order.
	# Easier to verify the output by following the path
	# If using an associative array, when printing the keys, the order will be random.
	declare -a cache=()
	# Copying the inital position. Need to exclude the case where the obstruction is being placed
	# on the starting position
	local init_x="$CUR_X" init_y="$CUR_Y"

	while in_bounds; do
		if test "$NEXT" != "#"; then
			local pos="$NEXT_X:$NEXT_Y"
			if ((NEXT_X == init_x && NEXT_Y == init_y)) || contains "$pos"; then
				advance
				continue
			fi
			cache+=("$NEXT_X:$NEXT_Y")
		fi
		advance
	done
	IFS=$'\n'
	echo "${cache[*]}"
}

# uses the outer scope variable 'cache' as the array
function contains()
{
	val="$1"
	for elem in "${cache[@]}"; do
		test "$elem" = "$val" && return 0
	done
	return 1
}

function test_obstructions()
{
	local cachefile="$1"
	if ! test -f "$cachefile"; then
		echo "Missing cache file argument" >&2
		exit 1
	fi

	local cores=$(nproc)
	local -a candidates=() verified_loop=()
	local -A jobs=()
	local i=0
	# Array of coordinates to place an obstruction at
	mapfile -t candidates <"$cachefile"
	# Test each obstruction for an infinite loop in parallel
	# Use a subshell for each cpu core (from nproc)
	# Start the n subprocess immediately
	# Then after each one is done, start a new one
	#
	# To keep track of which coordinate resulted in an infinite loop
	# maintain an associative array 'jobs' with each subprocess id as key
	# and the index from 'candidates' as key
	#
	# 'wait -np id' waits for a single subprocess to end, returns the exit code and gives the subprocess id in `id`
	# With it, we can look into 'jobs', get the original 'i' and lookup the coords in 'candidates'
	# Finally by checking the exit code, we can see if those coords result in an infinite loop or not
	# 1 => infinite loop
	# 0 => guard escaped
	for (( ; i < cores && i < ${#candidates[@]}; i++)); do
		(test_candidate "$i") &
		jobs[$!]="$i"
	done
	while true; do
		wait -np id
		code=$?
		# When all jobs are done, wait will return immediatly and `id` will be empty
		test -z "$id" && break
		index=${jobs[$id]}
		unset 'jobs[$id]'
		coords=${candidates[$index]}
		if ((code == 1)); then
			echo "found loop at coords($coords)"
			verified_loop+=("$coords")
		fi
		if ((i < ${#candidates[@]})); then
			(test_candidate "$i") &
			jobs[$!]="$i"
			((i++))
		fi
	done
	echo "found ${#verified_loop[@]} loops total"
	echo "${verified_loop[*]}"
}

function test_candidate()
{
	local x y
	local candidate=${candidates[i]}
	x=${candidate%:*}
	y=${candidate#*:}
	set_cell "$x" "$y" "#"

	# Need to recompute next_square
	# only for the case the block was placed right after the starting position
	next_square
	while in_bounds; do
		if ! advance; then
			return 1
		fi
	done
	return 0
}

# set x,y and DIRECTION
find_pos
# compute dx and dy
set_velocity
next_square

log_state

case "$1" in
find | test)
	func="$1"
	shift
	"${func}_obstructions" "$@"
	;;
*) echo "Invalid command $1. Must one of \"find\", \"test\"" >&2 ;;
esac
