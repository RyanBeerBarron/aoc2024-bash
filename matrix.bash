# Function to manipulate 2d array like structure
# Global variables: matrix, max_i, max_j, cell, i, j
#
# Matrix has a (i,j) coordinate system. Since this is a simple array of strings,
# 'i' goes from top to bottom, the first row is 0, and the last row is 'max_i'
# 'j' is the index of characters inside the string for each row. '0' is the first char, 'max_j' is the last char

# @var[out] matrix  array representing a 2d array / matrix
# @var[out] max_i   largest value for the 'i' coordinate
# @var[out] max_j   largest value for the 'j' coordinate
function build_matrix ()
{
	mapfile -t matrix
	max_i="${#matrix[@]}"
	max_j="${#matrix[0]}"
}

# @param $1 func   function to be called on each cell
function for_each_cell ()
{
	local func="$1"
	for ((i=0; i<max_i; i++)); do
		for ((j=0; j<max_j; j++)); do
			get_cell "$i" "$j"
			log_trace "Executing func=$func on cell($i,$j)=$cell"
			eval "$func" "$cell"
		done
	done
}

# @var[in] i        row index to retrieve cell at
# @var[in] j        column index to retrieve cell at
# @var[out] cell    value of cell at coordinate (i,j) in matrix 'matrix'
# @return   0 if cell is retrieved successfully
#           1 if indexes are out of bounds
function get_cell ()
{
	if (( i < 0 || i >= max_i || j < 0 || j >= max_j )); then return 1; fi
	local line=${matrix[i]}
	cell=${line:j:1}
}
