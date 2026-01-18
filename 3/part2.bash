read -rd '' input
cleaned_input=""
((do = 1))
while true; do
	if ((do == 1)); then
		if test "$input" != "${input#*don\'t()}"; then
			cleaned_input="${cleaned_input}${input%%don\'t()*}"
			input="${input#*don\'t()}"
			((do = 0))
		else
			break
		fi
	else
		if test "$input" != "${input#*do()}"; then
			input="${input#*do()}"
			((do = 1))
		else
			break
		fi
	fi
done

total=0
while test "$cleaned_input" != "${cleaned_input#*mul}"; do
	cleaned_input="${cleaned_input#*mul}"
	if [[ "$cleaned_input" =~ ^\(([0-9]{1,3}),([0-9]{1,3})\) ]]; then
		((product = ${BASH_REMATCH[1]} * ${BASH_REMATCH[2]}))
		((total += product))
	fi
done
echo "$total"
