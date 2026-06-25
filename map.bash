# Function to manipulate 2d array like structure
# Global variables: map, max_i, max_j, cell, i, j

function build_map ()
{
	mapfile -t map
	max_i="${#map[@]}"
	max_j="${#map[0]}"
}

function for_each_cell ()
{
	local func="$1"
	for ((i=0; i<"$max_i"; i++)); do
		for ((j=0; j<"max_j"; j++)); do
			get_cell "$i" "$j"
			log_trace "Executing func=$func on cell($i,$j)=$cell"
			eval "$func" "$cell"
		done
	done
}

function get_cell ()
{
	if (( i < 0 || i >= max_i || j < 0 || j >= max_j )); then return 1; fi
	local line=${map[i]}
	cell=${line:j:1}
}

function set_cell()
{
	local val="$1"
	if (( i < 0 || i >= max_i || j < 0 || j >= max_j )); then return 1; fi
	local line=${map[i]}
	set_char "$line" "$y" "$val"
	map[i]="$string_out"
}
