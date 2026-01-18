# For part 2, this solution is done in two pass
# First pass is building a clean input string by removing all deactivated 'mul()'
# It removes everything all the string of the form "don't().*do()"
# And inversely, it keeps the content of every string in the form "do().*don't()"

read -rd '' input
cleaned_input=""
((do = 1))
while true; do
	if ((do == 1)); then
		# If a "don't()" is present in the input
		# Take everything up to it in the cleaned input
		# And advance up to that point
		if test "$input" != "${input#*don\'t()}"; then
			cleaned_input="${cleaned_input}${input%%don\'t()*}"
			input="${input#*don\'t()}"
			((do = 0))
		else
			# No more "don't()" present in the input
			# All of the remaining 'mul' are to be counted in the final result
			cleaned_input="${cleaned_input}${input%%don\'t()*}"
			break
		fi
	else
		# The 'mul()' are deactivated here, so ignore the input unti the next 'do()'
		if test "$input" != "${input#*do()}"; then
			input="${input#*do()}"
			((do = 1))
		else
			break
		fi
	fi
done

# Same as part 1 now
total=0
while test "$cleaned_input" != "${cleaned_input#*mul}"; do
	cleaned_input="${cleaned_input#*mul}"
	if [[ "$cleaned_input" =~ ^\(([0-9]{1,3}),([0-9]{1,3})\) ]]; then
		((product = ${BASH_REMATCH[1]} * ${BASH_REMATCH[2]}))
		((total += product))
	fi
done
echo "$total"
