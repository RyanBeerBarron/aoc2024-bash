source ../common.bash

: ${LOG_LEVEL:=$LOG_DEBUG}

case "$1" in
part1) part=1 ;;
part2) part=2 ;;
esac

function combo ()
{
	case "$operand" in
	[0-3]) : ;;
	4) ((operand = A)) ;;
	5) ((operand = B)) ;;
	6) ((operand = C)) ;;
	esac
}

function bxl ()
{
	log_trace "XOR B=$B with $operand, storing into B"
	((B = B ^ operand))
}

function bst ()
{
	combo
	log_trace "computing $operand modulo 8. storing into B"
	((B = operand & 07))
}

function jnz ()
{
	if ((A == 0)); then ((pc+=2)); return; fi
	log_trace "Jumping to pc=$operand"
	((pc = operand))
}

function bxc ()
{
	log_trace "XOR B=$B with C=$C, storing into B"
	((B = B ^ C))
}

function out ()
{
	combo
	((operand = operand & 07))
	log_trace "computing $operand modulo 8. storing into output"
	output+=("$operand")
	if test "$part" = "2"; then
		log_trace "On i=$i program[i]=${program[i]} operand=$operand"
		if ((program[i] != operand)); then flag=1 ; return 1; fi
	fi
	((i++))
}

function dv ()
{
	local numerator denominator result
	combo
	case "$opcode" in
	0) target=A ;;
	6) target=B ;;
	7) target=C ;;
	esac
	((numerator = A))
	((denominator = 2 ** operand))
	((result = numerator / denominator))
	log_trace "Dividing A=$A by 2^$operand, storing into $target"
	eval "$target=$result"
}

function store ()
{
	case "$opcode" in
	0) ((A = result)) ;;
	6) ((B = result)) ;;
	7) ((C = result)) ;;
	esac
}

function test-A-values ()
{
	for ((a=core; ; a+=cores)); do
		A="$a"
		B="$orig_B"
		C="$orig_C"
		log_debug "testing quine program with A=$A"
		if execute-program; then
			log_info "Found quine program with A=$a"
			exit 2;
		fi
	done
}

function execute-program ()
{
	declare -a output=()
	local i=0 pc=0 flag=0
	IFS=,
	while ((pc < program_len)); do
		incr="true"
		opcode=${program[pc]}
		operand=${program[pc+1]}
		log_trace "PC=$pc, opcode=$opcode, operand=$operand"
		case "$opcode" in
		0|6|7) dv ;;
		1) bxl ;;
		2) bst ;;
		3) jnz ; incr=false ;;
		4) bxc ;;
		5) out ;;
		esac
		if ((flag == 1)); then
			printf -v msg "Failed for A=$a (base 8=%o): output ${output[*]} unlike program ${program[*]}" "$a"
			log_info "$msg"
			return 1
		fi
		log_trace "Register: A=$A, B=$B, C=$C"
		log_trace "Output: ${output[*]}\n"

		if test "$incr" = "true"; then ((pc += 2)); fi
	done

	test "${output[*]}" = "${program[*]}"
	return
}

read register_a_line
read register_b_line
read register_c_line
read empty
read program_line

[[ "$register_a_line" =~ [0-9]+ ]]
A="${BASH_REMATCH[0]}"

[[ "$register_b_line" =~ [0-9]+ ]]
B="${BASH_REMATCH[0]}"
orig_B="$B"

[[ "$register_c_line" =~ [0-9]+ ]]
C="${BASH_REMATCH[0]}"
orig_C="$C"

log_debug "At start, register A=$A, register B=$B, register C=$C"

declare -a program=()

program_line="${program_line#Program: }"
exec 3<<<"$program_line"
while read -u 3 -n1 c; do
	if [[ "$c" != [0-9] ]]; then continue; fi
	program+=("$c")
done
exec 3<&-
log_debug "Program is: ${program[@]}"
program_len=${#program[@]}

if test "$part" = "1"; then execute-program; fi
if test "$part" = "2"; then
	trap 'kill 0' EXIT
	run_in_parallel test-A-values
	wait -n
fi
