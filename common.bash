__DIR=$(cd "$( dirname ${BASH_SOURCE[0]} )" && pwd)
source "$__DIR"/logger.bash
source "$__DIR"/array.bash
source "$__DIR"/matrix.bash

cores=$(nproc)

function run_in_parallel ()
{
	local i
	local func="$1"
	for ((i=0; i<cores; i++)); do
		(
			pid="$i"
			elapsed=$( { time $func; } 2>&1 )
			log_info "ran for:" $elapsed
		) &
	done
}
