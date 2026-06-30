source ../common.bash
: ${LOG_LEVEL:=$LOG_TRACE}

# Array of coords belonging to same plot. Each string is space separated list of coords.
declare -a plots=()
declare -A explored_plant=()

function explore_plot ()
{
	local i="$i" j="$j" plant="$cell"
	local coord="$i:$j"
	if test "${explored_plant[$coord]}" != ""; then
		return
	fi
	plot="$coord"
	explored_plant[$coord]="$cell"
	log_debug "Starting to explore plot of type $plant at ($i,$j)"
	explored_plot_recursive $((i-1)) "$j"
	explored_plot_recursive "$i" $((j+1))
	explored_plot_recursive "$i" $((j-1))
	explored_plot_recursive $((i+1)) "$j"
	log_debug "Done explored plot of type $plant at ($i,$j), entire plot: $plot"
	plots+=("$plot")
}

function explored_plot_recursive ()
{
	local i="$1" j="$2"
	local coord="$i:$j"
	if ! get_cell; then
		return
	fi
	if test "${explored_plant[$coord]}" = "$plant"; then
		return
	fi
	if test "$cell" = "$plant"; then
		log_trace "Found new plant of same type at ($coord)"
		explored_plant[$coord]="$plant"
		plot="$plot $coord"
		explored_plot_recursive $((i-1)) "$j"
		explored_plot_recursive "$i" $((j+1))
		explored_plot_recursive "$i" $((j-1))
		explored_plot_recursive $((i+1)) "$j"
	fi
}

function build_set ()
{
	for coord in "$@"; do
		set_plants[$coord]="1"
	done
}

# @var[out] price
function compute_price ()
{
	set -- $1
	log_debug "computing price for plot($#) $@"
	local area="$#" perimeter=0
	local -A set_plants=()
	local -a neighbors=()
	build_set "$@"
	log_trace "${set_plants[@]@A}"
	for coord in "${!set_plants[@]}"; do
		enumerate_neighboring_coord "$coord"
		log_trace "neighbors = ${neighbors[@]}"
		for neighbor in "${neighbors[@]}"; do
			if test "${set_plants[$neighbor]}" = ""; then
				log_debug "need a fence from coord($coord) to coord($neighbor)"
				((perimeter++))
			fi
		done
	done
	log_info "price of plot $@: $price = $area * $perimeter"
	((total = area * perimeter))
}

# @param $@ plot
# @var[out] topleft_corner
function find_topleft_corner ()
{
	local min_i="$max_i" min_j="$max_j"
	local i j
	for coord; do
		split_coord "$coord" i j
		((min_i = i < min_i ? i : min_i))
	done
	for coord; do
		split_coord "$coord" i j
		if (( i != min_i )); then continue; fi
		((min_j = j < min_j ? j : min_j))
	done
	topleft_corner="$min_i:$min_j"
}

function compute_price_batch ()
{
	set -- $1
	log_debug "computing batch price for plot($#) $@"
	local direction coord="$1" i j
	split_coord "$coord" i j
	local area="$#" sides=0 cell
	get_cell
	local -A set_plants=()
	build_set "$@"
	log_trace "${set_plants[@]@A}"
	for coord; do
		for direction in "1:1" "-1:1" "1:-1" "-1:-1"; do
			if is_corner "$coord" "$direction"; then ((sides++)); log_debug "($coord) is a corner in direction $direction"; fi
		done
	done
	((total = area * sides))
	log_info "For plant $cell at coord($coord), total=$total with area=$area and sides=$sides"
}

function is_corner ()
{
	local coord="$1" direction="$2"
	local hoz vert diag count=0
	local i j di dj
	split_coord "$coord" i j
	split_coord "$direction" di dj
	hoz="$i:$((j+dj))"
	diag="$((i+di)):$((j+dj))"
	vert="$((i+di)):$j"
	log_trace "the four points cur=$coord, hoz=$hoz, vert=$vert, diag=$diag"
	if test "${set_plants[$hoz]}" != "1" &&
		test "${set_plants[$vert]}" != "1"; then
		log_trace "convex corner at ($coord)"
		return 0
	fi
	if test "${set_plants[$hoz]}" = "1" &&
		test "${set_plants[$vert]}" = "1" &&
		test "${set_plants[$diag]}" != '1'; then
		log_trace "concave corner at ($coord)"
		return 0
	fi
	return 1
}

case "$1" in
part1) func="compute_price" ;;
part2) func="compute_price_batch" ;;
*) echo "invalid argument $1" >&2 ;;
esac
build_matrix

for_each_cell 'explore_plot'
sum_in_parallel "$func" "plots"
echo "$total"
