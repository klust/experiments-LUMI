library(foreach)
library(doSNOW)

cl <- makeCluster()
registerDoSNOW(cl)

system.time(
    foreach(i = 1:100) %dopar% sum(sort(runif(1e7)))  # parallel execution
)

stopCluster(cl)
