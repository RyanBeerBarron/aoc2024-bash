declare -A count=()

while read first second; do
	((count[$second]++))
done <input2

((total = 0))
while read first second; do
	((total += first * count[$first]))
done <input2
echo "$total"
