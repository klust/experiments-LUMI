#include <stdio.h>
#include <mpi.h>
#include <sched.h>
#include <hip/hip_runtime.h>


int main(int argc, char *argv[]){

    int deviceCount;
    hipGetDeviceCount(&deviceCount);

	MPI_Init(&argc, &argv);

    MPI_Info info;
    MPI_Info_create(&info);

    MPI_Comm newCommunicator;
    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, 0, info, &newCommunicator);

    int processesInTotal;
    int rankInTotal;
    MPI_Comm_size(MPI_COMM_WORLD, &processesInTotal);
    MPI_Comm_rank(MPI_COMM_WORLD, &rankInTotal);

    int processesOnNode;
    int rankOnNode;
    MPI_Comm_size(newCommunicator, &processesOnNode);
    MPI_Comm_rank(newCommunicator, &rankOnNode);

    int useDevice = rankOnNode;

    hipSetDevice(useDevice);

    char busid[65];
    hipDeviceGetPCIBusId(busid, (int) 65, useDevice);

    MPI_Barrier( MPI_COMM_WORLD );

	printf("Global %02d/%02d local %02d/%02d busID %s\n",
		   rankInTotal, processesInTotal, rankOnNode, processesOnNode, busid);

    MPI_Barrier(MPI_COMM_WORLD);
	MPI_Finalize();

	return 0;

}
