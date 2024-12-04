check_mas ()
{
    local char1="$1" char2="$2"
    if test "$char1" = "M"
    then
        test "$char2" = "S"
    elif test "$char1" = "S"
    then
        test "$char2" = "M"
    else
        return 1
    fi
}

mapfile -t input
(( row_nr = ${#input[@]} ))
(( col_nr = ${#input[0]} ))
(( found = 0 ))

# Loop only through the inner square of input.
# Only looking for 'A' that have the four corners inside the bounds
for (( row_idx = 1; row_idx < row_nr - 1; row_idx++ ))
do
    row="${input[row_idx]}"
    for (( col_idx = 1; col_idx < col_nr - 1; col_idx++ ))
    do
        if test "${row:col_idx:1}" = "A"
        then
            (( topleft_row_idx = row_idx - 1 ))
            (( topleft_col_idx = col_idx - 1 ))
            topleft_char="${input[topleft_row_idx]:topleft_col_idx:1}"

            (( bottomright_row_idx = row_idx + 1 ))
            (( bottomright_col_idx = col_idx + 1 ))
            bottomright_char="${input[bottomright_row_idx]:bottomright_col_idx:1}"
            check_mas "$topleft_char" "$bottomright_char" || continue

            (( topright_row_idx = row_idx - 1 ))
            (( topright_col_idx = col_idx + 1 ))
            topright_char="${input[topright_row_idx]:topright_col_idx:1}"

            (( bottomleft_row_idx = row_idx + 1 ))
            (( bottomleft_col_idx = col_idx - 1 ))
            bottomleft_char="${input[bottomleft_row_idx]:bottomleft_col_idx:1}"

            check_mas "$topright_char" "$bottomleft_char" || continue

            (( found++ ))
        fi
    done
done
echo "$found"
