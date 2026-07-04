source ../common.bash

: ${LOG_LEVEL:=$LOG_TRACE}

case "$1" in
part2) part2=true ;;
esac

# Globals
declare A_X A_Y B_X B_Y prize_X prize_Y
regex_button="Button [AB]: X\+([0-9]+), Y\+([0-9]+)"
regex_prize="Prize: X=([0-9]+), Y=([0-9]+)"

function log_state ()
{
	log_trace "A: X+$A_X, Y+$A_Y, B: X+$B_X, Y+$B_Y, Prize: X=$prize_X, Y=$prize_Y"
	log_trace "Eq X: Prize X $prize_X = A * $A_X + B * $B_X"
	log_trace "Eq Y: Prize Y $prize_Y = A * $A_Y + B * $B_Y"
}

function read_claw_machine ()
{
	local lineA lineB prize_line
	read lineA
	read lineB
	read prize_line
	if test -z "$lineA" || test -z "$lineB" || test -z "$prize_line"; then
		return 1
	fi
	[[ "$lineA" =~ $regex_button ]]
	A_X=${BASH_REMATCH[1]}
	A_Y=${BASH_REMATCH[2]}
	[[ "$lineB" =~ $regex_button ]]
	B_X=${BASH_REMATCH[1]}
	B_Y=${BASH_REMATCH[2]}
	[[ "$prize_line" =~ $regex_prize ]]
	prize_X=${BASH_REMATCH[1]}
	prize_Y=${BASH_REMATCH[2]}
}

# @param $1 numerator
# @param $2 denominator
# @var[out] ratio
function fp_div ()
{
	local num="$1" denom="$2"
	ratio=$(bc <<<"scale=10; $num / $denom")
}

# @param $1 floating point string representation
function is_integer ()
{
	local number="$1"
	local decimal fractional
	decimal=${number%.*}
	fractional=${number#*.}
	shopt -s extglob
	[[ "$fractional" == +(0) ]]
	return
}


((total=0))
while read_claw_machine; do
	read empty_line
	((x_factor = A_X))
	((y_factor = A_Y))
	if test "$part2" = "true"; then
		((prize_X += 10000000000000))
		((prize_Y += 10000000000000))
	fi
	log_state

	((A_X *= y_factor, B_X *= y_factor, prize_X *= y_factor))
	((A_Y *= x_factor, B_Y *= x_factor, prize_Y *= x_factor))
	log_state

	((B_X -= B_Y, prize_X -= prize_Y))
	fp_div "$prize_X" "$B_X"
	B="$ratio"
	if ! is_integer "$B"; then
		log_info "B:$B is not an integer"
		continue;
	fi
	B=${B%.*}
	log_debug "B=$B from $prize_X/$B_X"
	numerator=$((prize_Y - B * B_Y))
	fp_div "$numerator" "$A_Y"
	A="$ratio"
	if ! is_integer "$A"; then
		log_info "A:$A is not an integer"
		continue;
	fi
	A=${A%.*}
	log_debug "A=$A from $numerator/$A_Y"
	log_info "Adding to total $((A * 3)) + $((B))"
	((total += A * 3 + B))
done
echo "$total"
