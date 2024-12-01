mkfifo first_col second_col first_col_sorted second_col_sorted
while read first second
do
    echo "$first" >&3
    echo "$second" >&4
done 3>first_col 4>second_col <input1 &

sort -g <first_col >first_col_sorted &
sort -g <second_col >second_col_sorted &

(( total = 0 ))
while read -u 3 first && read -u 4 second
do
    (( diff = first - second ))
    (( diff = diff < 0 ? -diff : diff ))
    (( total += diff ))
done 3<first_col_sorted 4<second_col_sorted
echo "$total"

rm first_col second_col first_col_sorted second_col_sorted
