source ../common.bash

: ${LOG_LEVEL:="$LOG_TRACE"}

function compute_checksum ()
{
	for ((i=0; i<${#disk[@]}; i++)); do
		num=${disk[i]}
		if test "$num" = '.'; then continue; fi
		((checksum += num * i))
		log_trace "adding $num * $i\t" \
			"new checksum = $checksum"

	done
}

function part1_build_disk ()
{
	IFS=''
	part1_build_disk_from_map
	log_debug "disk before compression=${disk[*]}"

	part1_compress_disk
	log_debug "disk after compression=${disk[*]}"
}

function part1_build_disk_from_map ()
{
	for ((i=0; i<${#diskmap}; i++)); do
		length="${diskmap:i:1}"
		log_trace "diskmap[$i]=$length"
		if test "$type" = "file"; then
			char="$filenumber"
			((filenumber++))
			type="space"
		else
			char='.'
			type="file"
		fi
		for ((j=0; j<length; j++)); do
			disk+=("$char")
		done
	done
}

function part1_compress_disk ()
{
	((i=0, j=${#disk[@]}-1 ))
	left=${disk[i]}
	right=${disk[j]}
	while ((i < j)); do
		if test "$left" != '.'; then
			((i++))
			left=${disk[i]}
			continue
		fi
		if test "$right" == '.'; then
			((j--))
			right=${disk[j]}
			continue
		fi
		swap "disk" "$i" "$j"
		left=${disk[i]}
		right=${disk[j]}
	done
}


function part2_build_disk_from_map ()
{
	for ((i=0; i<${#diskmap}; i++)); do
		length="${diskmap:i:1}"
		log_trace "diskmap[$i]=$length"
		if test "$type" = "file"; then
			char="$filenumber"
			((filenumber++))
			type="space"
		else
			char='.'
			type="file"
		fi
		if ((length == 0)); then continue; fi
		disk+=("$char:$length")
	done
}

function find_next_space ()
{
	local i
	for ((i=0; i<${#disk[@]}; i++)); do
		ele=${disk[i]}
		if [[ "$ele" = .:[0-9] ]]; then ((first_space = i)); return; fi
	done
	return 1
}

function part2_compress_disk ()
{
	local first_space=1
	local file file_copy file_moved space file_size space_size

	local i j
	for ((j=${#disk[@]}-1; j >= 0; j--)); do
		file=${disk[j]}
		if [[ "$file" = .:[0-9] ]]; then continue; fi
		((file_moved = 0))
		for ((i=first_space; i<j && file_moved == 0; i++)); do
			space=${disk[i]}
			if [[ "$space" != .:[0-9] ]]; then continue; fi
			file_size="${file#*:}"
			space_size="${space#.:}"
			if (( file_size == space_size )); then
				log_debug "perfect match between $file idx=$j and $space idx=$i. Swapping"
				swap disk "$i" "$j"
				((file_moved = 1))
				find_next_space
			elif (( file_size > space_size)); then
				log_trace "Cannot move $file to $space"
				continue
			else
				log_debug "space greater than file, moving $file idx=$j to $space idx=$i. Splitting"
				file_copy="$file"
				file=".:$file_size"
				((space_size -= file_size))
				space=".:$space_size"
				disk[j]="$file"
				disk=("${disk[@]:0:i}" "$file_copy" "$space" "${disk[@]:i+1}")
				((file_moved = 1))
				((j++)) # increment j since disk size has been increased by one
				if ((first_space == i)); then ((first_space = i+1)); fi
			fi
		done
		log_trace "disk=${disk[*]}"
	done
}

function part2_expand_disk ()
{
	set -- "${disk[@]}"
	disk=()
	for element; do
		char=${element%:*}
		length=${element#*:}
		for ((i=0; i<length; i++)); do
			disk+=("$char")
		done
	done
}

function part2_build_disk ()
{
	part2_build_disk_from_map
	log_debug "disk before compression=${disk[*]}"

	part2_compress_disk
	log_debug "disk after compression=${disk[*]}"

	part2_expand_disk
	IFS=''
	log_debug "disk after expand=${disk[*]}"
}

case "$1" in
part1) build_disk="part1_build_disk";;
part2) build_disk="part2_build_disk";;
*) echo "invalid first argument=$1" >&2; exit 1; ;;
esac

read -d '' diskmap
log_debug "diskmap=$diskmap"

type="file"

((filenumber = 0))

disk=()

$build_disk

((checksum=0))
compute_checksum

echo "$checksum"
