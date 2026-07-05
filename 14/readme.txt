for part 2, I cheated a bit.
I looked online how people solved it and most people generated frames representing the robots at each second and looked for the pattern. I got a glipse of the exact pattern to look for
I also read that since the robots x position is repeated every 101 second since they wrap around and the modulo operator is used, and for the y position it's every 103 step

That means there are 101*103 distinct frames (it cannot be reduced since they are twin primes)

What I did was generate 1000 frames.
I saw that at frame 11, there was a vertical slice with many robots inside. Knowing what the tree shape was like, I explored further all the frames with the robots at the same width
So instead of generating every frame, with the width and height based on the current second number, I fixed the width and generated the frames for every height possible
In essence I was looping from 0 to 103 and generating every n frame where n === 11 mod 11.
i.e. frame 0 (11+101*k), frame 1 (11+101*k), frame 2 (11+101*k), etc...
k is some multiple of 101, but we don't know its value.

I got that frame 89 was the one with the xmas tree
What does that tell us ?
We know the frame we are looking for happened at second 'x' where:
	x === 11 mod 101 && x === 89 mod 103
	which can be rewritten as:
	x = 101*k + 11
	x = 103*j + 89
	=> 101*k + 11 = 103*j + 89
This is a diophantine equation, and I don't remember how to solve them.
So I asked wolfram alpha, and it gave:
> j = 101n + 62, k = 103n + 64, n is an integer

This gives us formulaes to generate pair of (j,k) that will satisfy our diophantine equation
for n=0, we have (j,k) = (62, 64), solve either formula containing 'x'
x = 101 * 64 + 11
OR
x = 103 * 62 + 89
both give x = 6475.

After this, I added a function to build a single frame given input second 'n' and verified if it contained the xmas tree
