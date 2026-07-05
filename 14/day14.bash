source ../common.bash

: ${LOG_LEVEL:=$LOG_TRACE}

case "$1" in
sample)
	part1=true
	WIDTH=11
	HEIGHT=7
	;;
input)
	part1=true
	WIDTH=101
	HEIGHT=103
	;;
part2)
	part2=true
	WIDTH=101
	HEIGHT=103
	;;
esac

# Globals
declare MIDDLE_WIDTH MIDDLE_HEIGHT
((MIDDLE_WIDTH = (WIDTH-1)/2 , MIDDLE_HEIGHT = (HEIGHT-1)/2 ))
declare TOPLEFT_Q_COUNT TOPRIGHT_Q_COUNT BOTLEFT_Q_COUNT BOTRIGHT_Q_COUNT
declare pos_x pos_y v_x v_y

log_debug "Arena dimensions are WIDTH=$WIDTH, HEIGHT=$HEIGHT"
log_debug "Middle row is at y=$MIDDLE_HEIGHT, middle column is at x=$MIDDLE_WIDTH"

# @param $1 x coordinate
# @param $2 y coordinate
function find_quadrant ()
{
	local x="$1" y="$2"
	if (( x == MIDDLE_WIDTH || y == MIDDLE_HEIGHT )); then
		log_debug "robot($x,$y) is in the middle"
		return;
	fi

	if   (( x < MIDDLE_WIDTH && y < MIDDLE_HEIGHT)); then
		log_debug "robot($x,$y) is in the top left quadrant"
		((TOPLEFT_Q_COUNT++));
	elif (( x < MIDDLE_WIDTH && y > MIDDLE_HEIGHT)); then
		log_debug "robot($x,$y) is in the bottom left quadrant"
		((BOTLEFT_Q_COUNT++));
	elif (( x > MIDDLE_WIDTH && y < MIDDLE_HEIGHT)); then
		log_debug "robot($x,$y) is in the top right quadrant"
		((TOPRIGHT_Q_COUNT++));
	else
		log_debug "robot($x,$y) is in the bottom right quadrant"
		((BOTRIGHT_Q_COUNT++)); fi
}

# @param $1 position string
# @var[out] pos_x
# @var[out] pos_y
function parse_position ()
{
	local position="$1"
	position="${position#p=}"
	pos_x="${position%,*}"
	pos_y="${position#*,}"
}

# @param $1 velocity string
# @var[out] v_x
# @var[out] v_y
function parse_velocity ()
{
	local velocity="$1"
	velocity="${velocity#v=}"
	v_x="${velocity%,*}"
	v_y="${velocity#*,}"
}

function part1 ()
{
	while read position velocity; do
		parse_position "$position"
		parse_velocity "$velocity"
		log_trace "robot position($pos_x,$pos_y) with velocity($v_x,$v_y)"
		((pos_x = (pos_x + v_x*100) % WIDTH))
		((pos_y = (pos_y + v_y*100) % HEIGHT))
		if ((pos_x < 0)); then ((pos_x += WIDTH)); fi
		if ((pos_y < 0)); then ((pos_y += HEIGHT)); fi
		log_trace "after 100 seconds, robot position($pos_x,$pos_y)"
		find_quadrant "$pos_x" "$pos_y"
	done
	log_info "Got $TOPLEFT_Q_COUNT robots in the top left quadrant"
	log_info "Got $TOPRIGHT_Q_COUNT robots in the top right quadrant"
	log_info "Got $BOTLEFT_Q_COUNT robots in the bottom left quadrant"
	log_info "Got $BOTRIGHT_Q_COUNT robots in the bottom right quadrant"
	((total = TOPLEFT_Q_COUNT * TOPRIGHT_Q_COUNT * BOTLEFT_Q_COUNT * BOTRIGHT_Q_COUNT))
	echo "$total"
}

function build_map ()
{
	declare -g MAP=()
	local i j line
	for ((i=0; i<HEIGHT; i++)); do
		line=""
		for ((j=0; j<WIDTH; j++)); do
			line="${line}."
		done
		MAP+=("$line")
	done
	local oldifs="$IFS"
	IFS=$'\n'
	log_trace "map:\n${MAP[*]}"
	IFS="$oldifs"
}


function build_frames ()
{
	for ((i=core; i < HEIGHT; i+=cores)); do
		build_frame "$i"
	done

}

function build_frame ()
{
	local i="$1"
	log_info "i=$i"
	frame=("${MAP[@]}")
	exec {robots_fd}<<<"$robots"
	while read -u "$robots_fd" position velocity; do
		parse_position "$position"
		parse_velocity "$velocity"
		log_trace "robot position($pos_x,$pos_y) with velocity($v_x,$v_y)"
		((pos_x = (pos_x + v_x*11) % WIDTH))
		((pos_y = (pos_y + v_y*i) % HEIGHT))
		if ((pos_x < 0)); then ((pos_x += WIDTH)); fi
		if ((pos_y < 0)); then ((pos_y += HEIGHT)); fi
		line=${frame[pos_y]}
		line="${line:0:pos_x}@${line:pos_x+1}"
		frame[pos_y]="$line"
	done
	exec {robots_fd}<&-
	printf -v filename "frames/frame%04d.txt" "$i"
	oldifs="$IFS"
	IFS=$'\n'
	echo "${frame[*]}" >"$filename"
	IFS="$oldifs"
}

function part2 ()
{
	read -d '' robots
	build_map
	run_in_parallel build_frames
	wait
	# build_frame 6475
}

if test "$part1" = "true"; then
	part1
elif test "$part2" = "true"; then
	part2
fi
