# Day 1

The only external tools I used where 
- `mkfifo`
- `sort`
- `rm`

Writing a `sort` function in bash is doable, and for `mkfifo` and `rm` I have an alternate solution.
So none of them are mandatory. 

But using pipes allows me to read stdin only a single time, otherwise I have to read the input twice, this requires knowing the file path
Or it requires to store stdin in memory. (Although using `sort` does buffer the input in memory so...)

Otherwise, nothing too complex
