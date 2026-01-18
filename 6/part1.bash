shopt -s extglob

# Globals {{{
DEBUG=0
# load file in global array
mapfile -t map
max_y=${#map[@]}
max_x=${#map[0]}

cur_x=-1
cur_y=-1
direction=''
dx=0
dy=0
# }}}

function count_unique()
{
	total=0
	for ((i = 0; i < max_y; i++)); do
		line=${map[i]}
		line=${line//[^X]/}
		((total += ${#line}))
	done
	echo $total
}

function printmap()
{
	if test "$DEBUG" = '1'; then
		echo "============"
		local IFS=$'\n'
		echo "${map[*]}"
		echo "============"
	fi
}

function get_cell()
{
	local x=$1 y=$2
	line=${map[y]}
	echo ${line:x:1}
}

function set_cell()
{
	local x=$1 y=$2 val=$3
	line=${map[y]}
	set_char line $x $val
	map[y]=$line
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

# Join an array with delimiter 'delim'
# $1(required): array ref
# $2(required): delim
# $3(required): output variable name
function join()
{
	local IFS
	local -n array="$1"
	IFS="$2"
	local str="${array[*]}"
	eval "$3='$str'"
}

function find_pos()
{
	for ((i = 0; i < ${#map[@]}; i++)); do
		local line=${map[i]}
		if [[ $line = *@(v|<|>|^)* ]]; then
			cur_y="$i"
			for ((j = 0; j < ${#line}; j++)); do
				if [[ "${line:j:1}" = @(v|<|>|^) ]]; then
					cur_x="$j"
				fi
			done
		fi
	done
	direction=$(get_cell $cur_x $cur_y)
}

function set_velocity()
{
	case "$direction" in
	^) dx=0 dy=-1 ;;
	\>) dx=1 dy=0 ;;
	\<) dx=-1 dy=0 ;;
	v) dx=0 dy=1 ;;
	esac
}

function advance()
{
	let advance_count++
	((next_x = cur_x + dx))
	((next_y = cur_y + dy))
	if ((next_x < 0 || next_x >= max_x || next_y < 0 || next_y >= max_y)); then
		finish
		return 1
	fi
	next=$(get_cell $((cur_x + dx)) $((cur_y + dy)))
	case "$next" in
	\. | X) step "$next_x" "$next_y" ;;
	\#) turn ;;
	esac
	return 0
}

function step()
{
	local next_x="$1" next_y="$2"
	set_cell "$cur_x" "$cur_y" "X"
	set_cell "$next_x" "$next_y" "$direction"
	cur_x="$next_x"
	cur_y="$next_y"
}

function turn()
{
	case "$direction" in
	^) direction='>' ;;
	\>) direction='v' ;;
	v) direction='<' ;;
	\<) direction='^' ;;
	esac
	set_velocity
}

function finish()
{
	set_cell "$cur_x" "$cur_y" "X"
}

function log_state()
{
	if test "$DEBUG" = '1'; then
		echo "pos is: x=$cur_x y=$cur_y"
		echo "direction=$direction"
		echo "velocity is: dx=$dx dy=$dy"
	fi
}

# set x,y and direction
find_pos
# compute dx and dy
set_velocity

log_state

# try to advance, can either step forward, turn, or finish the route
while advance; do
	:
done
printmap
count_unique
