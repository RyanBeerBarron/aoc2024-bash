# @param    $1:  path string
# @var[out] out: Shorten path string
function shorten_path ()
{
	local oldifs="$IFS"
	local i path
	IFS="/"
	set -- $1
	for ((i=0; i<$#-1; i++)); do
		path="$1"
		shift
		case "$path" in
		..)
			set -- "$@" "$path"
			;;
		*)
			set -- "$@" "${path:0:1}"
			;;
		esac
	done
	basename="$1"
	shift
	set -- "$@" "$basename"
	out="$*"
	IFS="$oldifs"
}
