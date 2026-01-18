IFS=$'\n' read -d '' -a input
((row_nr = ${#input[@]}))
((col_nr = ${#input[0]}))
((found = 0))

for row_idx in "${!input[@]}"; do
	row="${input[row_idx]}"
	for ((col_idx = 0; col_idx < col_nr; col_idx++)); do
		if test "${row:col_idx:1}" = "X"; then
			for x_v in -1 0 1; do
				((x_bound = row_idx + (x_v * 3)))
				((x_bound < 0 || x_bound >= row_nr)) && continue
				for y_v in -1 0 1; do
					((y_bound = col_idx + (y_v * 3)))
					((y_bound < 0 || y_bound >= col_nr)) && continue

					((m_x_idx = row_idx + x_v))
					((m_y_idx = col_idx + y_v))
					test "${input[m_x_idx]:m_y_idx:1}" != "M" && continue

					((a_x_idx = row_idx + (x_v * 2)))
					((a_y_idx = col_idx + (y_v * 2)))
					test "${input[a_x_idx]:a_y_idx:1}" != "A" && continue

					((s_x_idx = row_idx + (x_v * 3)))
					((s_y_idx = col_idx + (y_v * 3)))
					test "${input[s_x_idx]:s_y_idx:1}" != "S" && continue

					((found++))
				done
			done
		fi
	done
done
echo "$found"
