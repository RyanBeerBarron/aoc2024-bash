is_valid()
{
	IFS=','
	local idx page targets target count
	local pages=($1)
	declare -A count=()
	valid=1
	for idx in "${!pages[@]}"; do
		page="${pages[idx]}"
		targets=(${rules_map[$page]})
		for target in "${targets[@]}"; do
			if test "${count[$target]}"; then
				return 1
			fi
		done
		count[$page]=$idx
	done
	return 0
}

declare -A rules_map=()
IFS='|'
while read source_page target_page; do
	test -z "$source_page" && break
	targets="${rules_map[$source_page]}"
	if test -z "$targets"; then
		targets="$target_page"
	else
		targets="${targets},${target_page}"
	fi
	rules_map[$source_page]="$targets"
done

IFS=','
total=0
while read -a pages; do
	if is_valid "${pages[*]}"; then
		((mid_idx = ${#pages[@]} / 2))
		mid_value=${pages[$mid_idx]}
		((total += mid_value))
	fi
done
echo $total
