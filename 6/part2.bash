shopt -s extglob

# Globals {{{
DEBUG=0
# load file in global array
mapfile -t map
# Replacing all '.' square with 0 for easier checks/maths
map=( "${map[@]//./0}" )
max_y=${#map[@]}
max_x=${#map[0]}

cur_x=-1
cur_y=-1

next_x=-1
next_y=-1

cur=''
next=''

direction=''
dx=0
dy=0
# }}}
#
function log ()
{
    (( DEBUG == 0 )) && return
    test "$scope" = "simulation" && printf '\t'
    echo "$@"
}

function printmap ()
{
    local x y
    test "$DEBUG" = '0' && return
    log "============"
    for y in "${!map[@]}"
    do
        test "$scope" = 'simulation' && printf '\t'
        line=${map[y]}
        len=${#line}
        for (( x=0; x<len; x++ ))
        do
            char=${line:x:1}
            # echo "x=$x y=$y cur_x=$cur_x cur_y=$cur_y"
            if (( x == cur_x && y == cur_y ))
            then
                printf '\033[44m%c\033[0m ' "$char"
            elif (( x == outer_next_x && y == outer_next_y ))
            then
                printf '\033[41m%c\033[0m ' "$char"
            elif (( x == next_x && y == next_y ))
            then
                printf '\033[42m%c\033[0m ' "$char"
            elif test "$char" = '#'
            then
                printf '\033[43m%c\033[0m ' "$char"
            elif [[ "$char" =~ ^[1-9a-f]+$ ]]
            then
                printf '\033[7m%c\033[0m ' "$char"
            else
                printf '%c ' "$char"
            fi
        done
        printf '\n'
    done
    log "============"
}

function get_cell ()
{
    local x=$1 y=$2
    line=${map[y]}
    echo ${line:x:1}
}

function set_cell ()
{
    local x=$1 y=$2 val=$3
    line=${map[y]}
    set_char line $x $val
    line="${line:0:$x}${val}${line:x+1}"
    map[y]=$line
}

# sets a new value in 'str' (which references a variable name) at index 'index' with value 'char'
# $1(required): variable ref to 'str'
# $2(required): index
# $3(required): char
function set_char ()
{
    local string=${!1}
    local index="$2"
    local char="$3"
    string="${string:0:index}${char}${string:index+1}"
    eval "$1='$string'"
}

function find_pos ()
{
    for (( i=0 ; i < ${#map[@]} ; i++ ))
    do
        local line=${map[i]}
        if [[ $line = *@(v|<|>|^)* ]]
        then
            cur_y="$i"
            for (( j=0 ; j < ${#line} ; j++ ))
            do
                if [[ "${line:j:1}" = @(v|<|>|^) ]]
                then
                    cur_x="$j"
                fi
            done
        fi
    done
    cur=$(get_cell "$cur_x" "$cur_y")
    case "$cur" in
    ^) direction=1 ;;
    \>) direction=2 ;;
    v) direction=4 ;;
    \<) direction=8 ;;
    esac
    cur="0"
    set_cell "$cur_x" "$cur_y" "0"
}

function set_velocity ()
{
    case "$direction" in
    1) dx=0 dy=-1 ;;
    2) dx=1 dy=0 ;;
    4) dx=0 dy=1 ;;
    8) dx=-1 dy=0 ;;
    esac
}

function advance ()
{
    # if bitwise AND returns true, we already walked on current square with current direction
    # echo "cur=$cur direction=$direction"
    if (( 0x${cur} & direction ))
    then
        log "loop"
        return 1
    fi
    if [[ "$next" =~ ^[0-9a-f]+$ ]]
    then
        log "step"
        step
    else
        log "turn"
        turn
    fi
    (( next_x = cur_x + dx ))
    (( next_y = cur_y + dy ))

    next=$(get_cell "$next_x" "$next_y")
    return 0
}

function step ()
{
    (( cur = 0x${cur} | direction ))
    (( cur > 9 )) && cur=$(hex $cur)
    set_cell "$cur_x" "$cur_y" $cur
    cur_x="$next_x"
    cur_y="$next_y"
    cur=$(get_cell $cur_x $cur_y)
}

function turn ()
{
    (( cur = 0x${cur} | direction ))
    (( cur > 9 )) && cur=$(hex $cur)
    set_cell "$cur_x" "$cur_y" $cur
    case "$direction" in
    1) direction=2 ;; # '^' -> '>'
    2) direction=4 ;; # '>' -> 'v'
    4) direction=8 ;; # 'v' -> '<'
    8) direction=1 ;; # '<' -> '^'
    esac
    set_velocity
}

function finish ()
{
    set_cell "$cur_x" "$cur_y" "X"
}

function log_state ()
{
    if test "$DEBUG" = '1'
    then
        log "pos is: x=$cur_x y=$cur_y"
        log "next is: x=$next_x y=$next_y"
        log "cur=$cur next=$next"
        log "direction=$(convert_direction) ($direction)"
        log "velocity is: dx=$dx dy=$dy"
    fi
}

function convert_direction ()
{
    case "$direction" in
    1) echo "^" ;;
    2) echo ">" ;;
    4) echo "v" ;;
    8) echo "<" ;;
    esac
}

function in_bounds ()
{
    (( next_x >= 0 && next_x < max_x && next_y >= 0 && next_y < max_y ))
}

let loop_found=0
function simulate_block ()
{
    test "$next" = "#" && return

    # Keep reference to variable from outer scope
    local outer_next_x="$next_x" outer_next_y="$next_y"
    # Create copy of map, pos, velocity, etc...
    local next_x="$next_x" next_y="$next_y" next="$next"
    local cur_x="$cur_x" cur_y="$cur_y" cur="$cur"
    local dx="$dx" dy="$dy" direction="$direction"
    local -a map=("${map[@]}")
    # Set next cell as a wall
    set_cell $outer_next_x $outer_next_y '#'
    next="#"
    log "starting new simulation with block at pos (x,y)=($next_x,$next_y)"
    local scope="simulation"
    local iter=0
    while in_bounds
    do
        printmap
        if ! advance
        then
            echo "found valid looping blocking at $outer_next_x,$outer_next_y"
            (( loop_found++ ))
            return
        fi
    done || log "outside"
}

function hex ()
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

# set x,y and direction
find_pos
# compute dx and dy
set_velocity


(( next_x = cur_x + dx ))
(( next_y = cur_y + dy ))
next=$(get_cell "$next_x" "$next_y")
log_state

# try to advance
scope=mainloop
iter=0
while in_bounds
do
    simulate_block
    advance
    printmap
    (( iter++ ))
done
echo "took $iter steps"
