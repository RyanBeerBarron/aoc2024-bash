is_valid ()
{
    local idx page targets target
    local -n internal_pages="$1"
    local -A count=()
    valid=$2
    for idx in "${!internal_pages[@]}"
    do
        page="${internal_pages[idx]}"
        targets=( ${rules_map[$page]} )
        for target in "${targets[@]}"
        do
            if test "${count[$target]}"
            then
                tmp="$page"
                source_idx="${count[$target]}"
                target_idx="$idx"
                internal_pages[source_idx]="$page"
                internal_pages[target_idx]="$target"
                is_valid "$1" 0
                return $?
            fi
        done
        count[$page]=$idx
    done
    return "$valid"
}

declare -A rules_map=()
IFS='|'
while read source_page target_page
do
    test -z "$source_page" && break
    targets="${rules_map[$source_page]}"
    if test -z "$targets"
    then
        targets="$target_page"
    else
        targets="${targets},${target_page}"
    fi
    rules_map[$source_page]="$targets"
done

IFS=','
total=0
while read -a pages
do
    if is_valid pages 1
    then
        (( mid_idx = ${#pages[@]} / 2 ))
        mid_value=${pages[$mid_idx]}
        (( total += mid_value ))
    fi
done
echo $total
