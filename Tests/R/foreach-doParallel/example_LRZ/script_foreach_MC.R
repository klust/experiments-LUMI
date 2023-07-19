library(foreach)
library(doParallel)
library(parallelly)

sprintf( "Running on %d core(s).", availableCores())
registerDoParallel(cores = availableCores())

system.time(
    foreach(i = 1:100) %dopar% sum(sort(runif(1e7)))  # parallel execution
)
