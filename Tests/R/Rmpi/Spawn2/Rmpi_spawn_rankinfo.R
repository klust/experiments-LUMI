#
# Rmpi test
#
library("Rmpi")

# Spawn (size-1) slaves, one being resevered for master.
#
size <- mpi.universe.size()
mpi.spawn.Rslaves(nslaves = size - 1)

# Identify each slave process and display a message
#
mpi.bcast.cmd(rank <- mpi.comm.rank())
mpi.bcast.cmd(size <- mpi.comm.size())
mpi.bcast.cmd(hostname <- mpi.get.processor.name())
mpi.remote.exec(paste("This is rank", rank, "of", size, "running on node: ", hostname))

# Close all slaves and finish
#
mpi.close.Rslaves(dellog = FALSE)
mpi.quit()
