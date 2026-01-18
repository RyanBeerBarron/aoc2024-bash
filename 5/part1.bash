is_valid()
{
	IFS=','
	local idx page targets target count
	declare -A count=()
	valid=1
	for idx in "${!PAGES[@]}"; do
		page="${PAGES[idx]}"
		targets=(${RULES_MAP[$page]})
		for target in "${targets[@]}"; do
			if test "${count[$target]}"; then
				return 1
			fi
		done
		count[$page]=$idx
	done
	return 0
}

declare -A RULES_MAP=()
IFS='|'
while read source_page target_page; do
	test -z "$source_page" && break
	targets="${RULES_MAP[$source_page]}"
	if test -z "$targets"; then
		targets="$target_page"
	else
		targets="${targets},${target_page}"
	fi
	RULES_MAP[$source_page]="$targets"
done

IFS=','
total=0
declare -a PAGES=()
while read -a PAGES; do
	if is_valid; then
		((mid_idx = ${#PAGES[@]} / 2))
		mid_value=${PAGES[$mid_idx]}
		((total += mid_value))
	fi
done
echo $total
