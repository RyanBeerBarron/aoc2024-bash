# How to run day 6

The solution for part 2 needs to be run in two parts.  
First run 'part2.bash' with the 'find' argument, this will output a list of coordinates, save that in a file.  
`$ bash part2.bash find <input.txt >cache.txt`  
Secondly run 'part2.bash' again but with the 'test' argument and the file created in the 'find' run.   
`$ bash part2.bash test cache.txt <input.txt`  
Always, pass either 'sample.txt' or 'input.txt' as stdin, pass the same one for both run.  

* 'find' will find all the coordinates of an obstruction we need to check.  
* 'test' will check each coordinates in the given file if it causes an infinite loop for the guard or not.


'part1.bash' is the same as the other days. Nothing special

# About solving day 6

Day 6 was **WAY** harder than the previous days to solve.  
Manipulating a 2d array to represent the map and modifying the cell content shows the limitation of bash.  
Bash array can only store strings. An array of array of characters is not possible.  
But part 1 was manageable, so I won't dwell on it

Part 2 on the other hand...


## Part 2

The first hurdle was the algorithm, which is in two parts
- How to determine if the guard is in a loop ?
- Where to place the obstruction ?

##### Are we in a loop yet ? 
Finding if the guard is in a loop is simple enough, but annoying to implement in Bash.  
If the guard steps on the same cell, while facing the same direction, he is in a loop. 
This is because his walk is fully deterministic, given his current position and his direction, his path is always the same.  
We need to keep track of every cell the guard has walked onto. And the direction he was facing.  
Since there are 4 directions, North (2^0) / East (2^1) / South (2^2) / West (2^3), it will be stored as a bitset.
Each cell will be represented with a single hex digit (which is **very** fortunate[^1])

When the guard step on a cell, if the current direction bit is already set, we can stop the walk and conclude he is in a loop
otherwise, add the current direction bit to the bitset of that cell and repeat.  
Done!

##### Surely we don't need to try every combination of obstructions, yes ?

Short answer: unfortunetaly we do.  
When I first saw part2, I was scared of any brute force algorithm. Since I'm using Bash, that won't scale.  
I tried to figure out if there was a trick to avoid testing an obstruction on every step the guard takes.  
But there is not such trick, for example given this map:
```
....#.
.....#
...#..
.^..#.
......
```
Normally the guard would simply walk forward, encounter zero obstruction and walk outside the map.  
But on the side are four obstructions configured to immediatly cause the guard to loop on two cells.  
The guard never walks near them, but they can't be ignored in this part of the problem.
If an obstruction is placed in the right spot, it will force the guard to turn and walk directly in the trap.  


We must to test every spot in the guard's path, because we don't know in the general case what's around him.  
We have to place an obstruction and see what happens.  

### Implementing part 2

##### First attempt 
Knowing what to do is great and all but we have to implement it in bash \*sigh\*  
My first attempt did not work and took **WAY** too long to run, around 8 hours or so.  
That version can be reviewed by checkout out commit *2b4df7ad*  
This first attempt used the same code from part 1, but after every step the guard took,
it would make a copy of the entire map and state, place an obstruction on the copy and verify from that point on if this lead to an infinite loop or not.  
After checking that, it would throw away the copy, restore the original state and resume the walk.  
This solution had 2 problems:
- If the guard walked twice on the same cell, the same obstruction would be counted twice
- After placing an obstruction, it would not start the walk from the beginning, leading to scenario that should never happen. The following example will explain this point:

Given this map
``` 
..........
....#.....
.........#
..........
..........
........#.
....^.....
..........
```

The guard walks and will reach this point:
``` 
..........
....#.....
....xxxxx#
....x...x.
....x<xxx.
....x...#.
....x.....
..........
```

At this stage, we might be tempted to place a new obstruction, but this is not how part 2 works.  
Obstruction are placed before the guard starts his walk. An obstruction placed right ahead would make the guard turn on his second step and his entire path would be different.  
This was a misunderstanding on my part / misusing my code from part 1. 

- For each obstruction, we need to verify the walk from the beginning.


##### Second attempt

In my second attempt, I solved all my problems by dividing the problem in two.
- Find all the coordinates where an obstruction needs to be placed, and make sure there are no duplicates
- For each coordinates, place an obstruction and simulate the guard walk and see if there is a loop or not

This also allowed me to solve the run time problem. This solution make it very obvious how to parallelize the work. Which was not the case with my first attempt
Each coordinate can be ran separately in a subshell, and running in a subshell also takes care of creating a copy of all the variable in Bash.  
With 5211 obstruction that need to be tested, it still took 27 minutes to run, on a 16 cores machine, but this better than the 8 hours (which is roughly 27 minutes * 16)

## What I learned from part 2

I had learned about Bash variable scoping previously but I really put it to the test in my first attempt.  
`local` variable are not really *local* like in other programming languages. Local variables are accessible in the current stack frame and in the next stack frames.
Once the stack frame that created them is over, those local variables are gone. In a sense they are global variable but are cleaned up once the function that created them returns.  
I made a lot of use of global variables in my first attempt and used `local` copies each time I needed to check an obstruction.   

My second attempt was even clearer since I used subshells in parallel to each run guard with a different obstruction. And subshell by default, create copies of all the variables.


-----
[^1]: Since the map it stored as an array of string, when a direction bitset exceeded the value `1001` (9), the new value would be inserted in the string, but 10 and any number greater than it, is two digit long
which causes the string to be longer, and results in a new column in my map. This is **really** bad, I **MUST** store all the values with a single char, for a hexadecimal value, that's fine. But if there 5 or more bits in the bitset, I would have needed to find another solution.
