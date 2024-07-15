#!/usr/bin/env python3

# Skip cores you don’t want to use for each rank 
cpu_of_rank_thread = [ # sparing first 1 core
                       # each 8-core
[ 1, 2, 3, 4, 5, 6, 7] , # local rank 0
[ 9,10,11,12,13,14,15] , # local rank 1 
[17,18,19,20,21,22,23] , # local rank 2 
[25,26,27,28,29,30,31] , # local rank 3 
[33,34,35,36,37,38,39] , # local rank 4 
[41,42,43,44,45,46,47] , # local rank 5 
[49,50,51,52,53,54,55] , # local rank 6 
[57,58,59,60,61,62,63] ] # local rank 7

num_ranks = len(cpu_of_rank_thread)
mask = ""
for rank in range(num_ranks):
    sum = 0
    num_threads_this_rank = len(cpu_of_rank_thread[rank])
    for thread in range( num_threads_this_rank ): 
        cpu = cpu_of_rank_thread[rank][thread] 
        two_pow = 2 ** cpu
        sum += two_pow
        if thread == num_threads_this_rank - 1: 
            if rank > 0:
                mask += ","
            mask += hex(sum)
    if rank == num_ranks - 1:
        print("mask=", mask)

