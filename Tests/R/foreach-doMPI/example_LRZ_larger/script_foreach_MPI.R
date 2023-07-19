library(foreach)
library(doMPI)

cl <- startMPIcluster()  # use verbose = TRUE for detailed worker message output
registerDoMPI(cl)

system.time(
    foreach(i = 1:100) %dopar% sum(sort(runif(1e7)))  # parallel execution
)

closeCluster(cl)
mpi.quit()
