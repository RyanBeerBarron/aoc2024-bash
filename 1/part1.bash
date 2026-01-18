# By using pipes, this solution does a single pass over stdin
# Beneficial if it was very large
mkfifo first_col second_col first_col_sorted second_col_sorted

sort -g <first_col >first_col_sorted &
sort -g <second_col >second_col_sorted &

{
	((total = 0))
	while read -u 3 first && read -u 4 second; do
		((diff = first - second))
		((diff = diff < 0 ? -diff : diff))
		((total += diff))
	done
	echo "$total"
} 3<first_col_sorted 4<second_col_sorted &

while read first second; do
	echo "$first" >&3
	echo "$second" >&4
done 3>first_col 4>second_col

wait
rm first_col second_col first_col_sorted second_col_sorted

#################################################
# Solution without using `mkfifo` and `rm`      #
# Less elegant but uses less external commands  #
# Also requires two passes over stdin			#
#################################################
# mapfile MAP
#
# function printmap()
# {
# 	printf '%s' "${MAP[@]}"
# }
#
# exec 3< <(while read first ignored; do echo $first; done <<< "$(printmap)" | sort)
# exec 4< <(while read ignored second; do echo $second; done <<< "$(printmap)" | sort)
#
# (( total = 0 ))
# while read -u 3 first && read -u 4 second
# do
#     (( diff = first - second ))
#     (( diff = diff < 0 ? -diff : diff ))
#     (( total += diff ))
# done
# echo "$total"
#
# exec 3<&-
# exec 4<&-
