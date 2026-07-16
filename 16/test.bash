source ../common.bash

part1_sample1_value=$(LOG_LEVEL=-1 bash day16.bash part1 <sample.txt)
part1_sample2_value=$(LOG_LEVEL=-1 bash day16.bash part1 <sample2.txt)

part2_sample1_value=$(LOG_LEVEL=-1 bash day16.bash part2 <sample.txt)
part2_sample2_value=$(LOG_LEVEL=-1 bash day16.bash part2 <sample2.txt)

((
	part1_sample1_value == 7036 &&
	part1_sample2_value == 11048 &&
	part2_sample1_value == 45 &&
	part2_sample2_value == 64
))
