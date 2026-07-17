source ../common.bash

part1_value=$(LOG_LEVEL=-1 bash day18.bash sample part1 <sample.txt)
part2_value=$(LOG_LEVEL=-1 bash day18.bash sample part2 <sample.txt)

((part1_value == 22)) && test "$part2_value" = "6,1"
