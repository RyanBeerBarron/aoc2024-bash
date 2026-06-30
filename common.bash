__DIR=$(cd "$( dirname ${BASH_SOURCE[0]} )" && pwd)
source "$__DIR"/array.bash
source "$__DIR"/escape_codes.bash
source "$__DIR"/logger.bash
source "$__DIR"/map.bash
source "$__DIR"/matrix.bash
source "$__DIR"/path.bash

cores=$(nproc)

function run_in_parallel ()
{
	local core
	local func="$1"
	for ((core=0; core<cores; core++)); do
		(
			elapsed=$( { time $func; } 2>&1 )
			log_info "ran for:" $elapsed
		) &
	done
}

# @param $1 func
# @param $2 array
# @var[out] total
function sum_in_parallel ()
{
	((total=0))
	local core i
	local func="$1"
	local -n array="$2"
	result_file=$(mktemp)
	exec {result_fd}>"$result_file"
	for ((core=0; core<cores; core++)); do
		(
			elapsed=$( { time __worker; } 2>&1 )
			log_info "worker $core ran for:" $elapsed
		) &
	done
	wait
	exec {result_fd}>&-
	exec {result_fd}<"$result_file"
	while read -u "$result_fd" subresult; do
		((total+=subresult))
	done
}

function __worker ()
{
	local i element sum
	((sum=0))
	for ((i=$core; i<${#array[@]}; i+=cores)); do
		element=${array[i]}
		eval "$func \"$element\""
		((sum += total))
	done
	echo "$sum" >&"$result_fd"
}
