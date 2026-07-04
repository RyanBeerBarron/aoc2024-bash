source common.bash
: ${LOG_LEVEL:="$LOG_INFO"}
shopt -s extglob

function verify_day ()
{
	if ! test -r "sample_answers.txt"; then return 2; fi
	# variable assignment does not do pathname expansion
	# when using those variable, do not quote them.
	sample1=sample?(1).txt
	sample2=sample?(2).txt
	read answer1 answer2 <"sample_answers.txt"

	if test -r part1.bash; then
		val1=$(LOG_LEVEL=$LOG_OFF bash part1.bash <$sample1)
		val2=$(LOG_LEVEL=$LOG_OFF bash part2.bash <$sample2)
	fi
	day_pattern=day+([0-9]).bash
	if test -r $day_pattern; then
		val1=$(LOG_LEVEL=$LOG_OFF bash $day_pattern part1 <$sample1)
		val2=$(LOG_LEVEL=$LOG_OFF bash $day_pattern part2 <$sample2)
	fi
	log_debug "Day $dir: val1=$val1 val2=$val2"
	(( val1 == answer1 && val2 == answer2 ))
}

log_debug "argc=$# argv=$@"
((ok=0, total=0))
for dir in {1..25}; do
	if ! test -d "$dir"; then continue; fi
	log_trace "verifying dir=$dir"
	((total++))
	pushd "$dir" >/dev/null 2>&1
	verify_day

	code=$?
	case "$code" in
	0) log_info "Day $dir is valid"; ((ok++)) ;;
	1)
		log_error \
			"Day $dir is invalid. " \
			"For part1: expected=$answer1 got $val1. " \
			"For part2: expected=$answer2 got $val2"
		;;
	2) log_warn "Day $dir does not have a solutions file" ;;
	*) log_error "Unknown error occured when testing day $dir" ;;
	esac
	popd >/dev/null 2>&1
done

echo "$ok tests passed out of $total total"
