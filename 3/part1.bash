source ../common.bash
LOG_LEVEL="$LOG_DEBUG"
total=0
read -rd '' input
while test "$input" != "${input#*mul}"; do
	input="${input#*mul}"
	if [[ "$input" =~ ^\(([0-9]{1,3}),([0-9]{1,3})\) ]]; then
		((n1=${BASH_REMATCH[1]}, n2=${BASH_REMATCH[2]}, product=n1 * n2))
		printf -v log_msg \
			'found mul with %-15s %-15s %-30s' \
			"first term=$n1," \
			"second term=$n2," \
			"total=$total+$product"
		log_debug "$log_msg"
		((total += product))
	fi
done
echo "$total"
