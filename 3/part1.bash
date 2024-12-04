total=0
read -rd '' input
while test "$input" != "${input#*mul}"
do
    input="${input#*mul}"
    if [[ "$input" =~ ^\(([0-9]{1,3}),([0-9]{1,3})\) ]]
    then
        (( product = ${BASH_REMATCH[1]} * ${BASH_REMATCH[2]} ))
        (( total += product ))
    fi
done
echo "$total"
