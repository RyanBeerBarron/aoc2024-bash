
# @var[in]  src map to read key-val pairs
# @var[out] dst map to write key-val pairs
function copy_map ()
{
	local -n src="$1" dst="$2"
	dst=()
	log_trace "copying ${src[@]@A} to ${dst[@]@A}"
	for key in "${!src[@]}"; do
		val="${src[$key]}"
		dst[$key]="$val"
	done
}
