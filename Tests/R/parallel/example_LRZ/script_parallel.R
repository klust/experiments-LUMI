# Based on an example from https://doku.lrz.de/parallelization-using-r-10747291.html
#
library(parallel)
library(parallelly)
  
ac <- detectCores()
sprintf( "Number of cores according to parallel::detectCores: %d", ac )
nc <- availableCores()
sprintf( "Number of cores according to parallelly::availableCores: %d", nc )
  
print( "lapply:" )
system.time(
    lapply(1:20, function(x) sum(sort(runif(1e7))))
)
  
print( "mclapply with mc.cores = 1:" )
system.time(
    mclapply(1:20, function(x) sum(sort(runif(1e7))), mc.cores = 1)
)

sprintf( "mclapply with mc.cores = %d:", nc )
system.time(
    mclapply(1:20, function(x) sum(sort(runif(1e7))), mc.cores = nc)
)

print( "mclapply without mc.cores argument:" )
system.time(
    mclapply(1:20, function(x) sum(sort(runif(1e7))))
)
print( "Not sure what is happening here as user time goes down but elapsed goes up." )

print( "mclapply with mc.cores = 20:" )
system.time(
    mclapply(1:20, function(x) sum(sort(runif(1e7))), mc.cores = 20)
)

