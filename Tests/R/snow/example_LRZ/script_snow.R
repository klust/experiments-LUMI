# Example taken from LRZ: https://doku.lrz.de/parallelization-using-r-10747291.html
#

library(snow)
  
cl <- makeCluster()
  
system.time(
    parLapply(cl, 1:100, function(x){
        sum(sort(runif(1e7)))
        }
    )
)
  
stopCluster(cl)

q(save="no")
