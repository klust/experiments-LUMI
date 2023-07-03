# A problem that is not yet understood

At some point compiling code that used `uint32_t` failed with the CCE 15.0.1 compiler.
It was impossible to consistently reproduce this on another node or at another time,
so it looks like something entered the environment that caused this problem, or that
there was a temporary DVS problem on the node I used leading to a corrupt include
file.
