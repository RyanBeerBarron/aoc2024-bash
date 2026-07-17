source ../common.bash

: ${LOG_LEVEL:=$LOG_TRACE}

case "$1" in
sample) max_x=7;    max_y=7;   end="6,6";   bytes=12 ;;
input)  max_x=71;   max_y=71;  end="70,70"; bytes=1024 ;;
esac

mapfile -t input
input_len=${#input[@]}
IFS=:

# build queue and cache
function build-cache-and-queue ()
{
	x=0
	y=0
	steps=0
	start="0,0"
	declare -gA cache=()
	declare -ga queue=()
	queue+=("$x:$y:$steps:$x,$y")
	cache["$x,$y"]="1"
	start_q=0
	end_q=1
}

function log-status ()
{
	log_debug "On pos=$pos with $steps steps"
}

function print-queue-stats ()
{
	local queue_len
	((queue_len = end_q - start_q))
	log_debug "Queue has len $queue_len: start_q=$start_q, end_q=$end_q"
}

function print-queue ()
{
	local queue_str=""
	local oldifs="$IFS"
	IFS="|"
	queue_str="${queue[*]}"
	log_trace "$queue_str"
	IFS="$oldifs"
}

function build-grid ()
{
	local count
	declare -gA grid=()
	for ((count = 0; count < bytes; count++)); do
		byte="${input[count]}"
		grid["$byte"]="#"
	done
}

function build-grid-str ()
{
	local x y
	printf -v grid_str "\n"
	for ((y=0 ; y < max_y; y++)); do
		for ((x=0; x < max_x; x++)); do
			local pos="$x,$y"
			printf -v grid_str "%s%s" "$grid_str" "${grid[$pos]:-.}"
		done
		printf -v grid_str "%s\n" "$grid_str"
	done
}

function print-grid ()
{
	local grid_str
	if ((LOG_LEVEL >= LOG_TRACE)); then
		build-grid-str
		log_trace "$grid_str"
	fi
}

function read-byte ()
{
	local byte="$1"
	set -- $key
	x=$1
	y=$2
}

function dequeue ()
{
	local key=${queue[start_q++]}
	set -- $key
	x=$1
	y=$2
	pos="$x,$y"
	steps=$3
	shift 3
	path="$*"
}

function enqueue ()
{
	local x="$1" y="$2" steps="$3"
	local pos="$x,$y"
	if (( x < 0 || x >= max_x || y < 0 || y >= max_y)); then
		log_trace "$pos is out of bounds. returning"
		return
	fi
	if test "${grid[$pos]}" = "#"; then
		log_trace "$pos is corrupted. returning"
		return;
	fi
	if test -n "${cache[$pos]}"; then
		log_trace "$pos is already seen. returning"
		return
	fi
	((steps++))
	queue[end_q++]="$x:$y:$steps:$path:$pos"
	cache[$pos]=1
}

function find-smallest-path ()
{
	build-grid
	build-cache-and-queue
	print-grid

	while ((start_q < end_q)); do
		dequeue
		if test "$pos" = "$end"; then break; fi
		log-status
		enqueue "$((x+1))" "$y" "$steps"
		enqueue "$((x-1))" "$y" "$steps"
		enqueue "$x" "$((y+1))" "$steps"
		enqueue "$x" "$((y-1))" "$steps"
		# print-queue
		# print-queue-stats
	done
	log_info "Path=$path"
	echo "$steps"
}

function find-first-blocking-byte ()
{
	local -A path_set=()
	for ((bytes = 0; bytes<input_len; bytes++)); do
		if ! should-rebuild; then continue; fi
		log_info "New corrupted byte on known path. Total corrupted bytes: $bytes"
		if ((bytes > 0)); then log_info "Byte ${input[bytes-1]} blocks known path"; fi
		build-grid
		# build-grid-str
		# log_debug "New grid: $grid_str"
		build-cache-and-queue
		while ((start_q < end_q)); do
			dequeue
			if test "$pos" = "$end"; then break; fi
			log-status
			enqueue "$((x+1))" "$y" "$steps"
			enqueue "$((x-1))" "$y" "$steps"
			enqueue "$x" "$((y+1))" "$steps"
			enqueue "$x" "$((y-1))" "$steps"
			# print-queue
			# print-queue-stats
		done
		if test "$pos" != "$end"; then result="${input[bytes-1]}"; return 0; fi
		log_info "Found path of $steps steps with $bytes corrupted bytes: $path"
		save-path
		# write-path-on-grid
		# build-grid-str
		# log_debug "Path: $grid_str"
	done
}

function should-rebuild ()
{
	if test "${#path_set[@]}" -eq 0; then return 0; fi
	# if doing multicore, need to check the last n bytes if any fall onto the known path
	# where n is number of cores/threads in parallel
	local new_byte=${input[bytes-1]}
	log_trace "new_byte=$new_byte, path_set=${!path_set[@]}"
	if test "${path_set[$new_byte]}" = "1"; then return 0; fi
	return 1
}

function save-path ()
{
	for node in $path; do
		path_set["$node"]=1
	done
}

function write-path-on-grid ()
{
	for node in $path; do
		grid["$node"]=O
	done
}

case "$2" in
part1) find-smallest-path ;;
part2) find-first-blocking-byte ;;
esac
echo "$result"
