/**********************************************************
"Hello World"-type program to test different srun layouts.

Written by Tom Papatheodore
**********************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <iomanip>
#include <string.h>
#include <mpi.h>
#include <sched.h>
#include <hip/hip_runtime.h>
#include <omp.h>

#define DEBUG
#define BARDPEAK

#define EXIT_SUCCESS         0
#define EXIT_WRONG_ARGUMENT  1
#define EXIT_HIP_ERROR       2

#if defined( BARDPEAK )

#define MAXGPUS                8
#define SINGLE_PCIBUSID_STRLEN 13  // Full bus IDs of the form: 0000:c1:00.0
#define LIST_PCIBUSID_STRLEN   MAXGPUS * (13 + 1) // 13: length of the items in the map below.
                                                  // 1: , and trailing \0 after last item

const char * const busid_map[MAXGPUS] = {
		"0000:c1:00.0",
		"0000:c6:00.0",
		"0000:c9:00.0",
		"0000:ce:00.0",
		"0000:d1:00.0",
		"0000:d6:00.0",
		"0000:d9:00.0",
		"0000:de:00.0"
    };
const char * const busid_map_values_short[MAXGPUS] = {
		"c1",
		"c6",
		"c9",
		"ce",
		"d1",
		"d6",
		"d9",
		"dc"
    };
const char * const busid_map_values_long[MAXGPUS] = {
	    "c1(GCD0/CCD6)",
		"c6(GCD1/CCD7)",
		"c9(GCD2/CCD2)",
		"cc(GCD3/CCD3)",
		"d1(GCD4/CCD0)",
		"d6(GCD5/CCD1)",
		"d9(GCD6/CCD4)",
		"dc(GCD7/CCD5)"
    };

#endif

// Macro for checking errors in HIP API calls
#define hipErrorCheck(call)                                                                     \
do {                                                                                            \
    hipError_t hipErr = call;                                                                   \
    if( hipErr != hipSuccess ){                                                                 \
        printf( "HIP Error - %s:%d: '%s'\n", __FILE__, __LINE__, hipGetErrorString( hipErr ) ); \
        exit( EXIT_HIP_ERROR );                                                                 \
    }                                                                                           \
} while(0)



//******************************************************************************
//
// print_help()
//
// Prints help information.
//

void print_help( const char *exe_name ) {

	fprintf( stderr,
		"\n"
        "%s\n"
		"\n",
        exe_name
	);
	fprintf( stderr,
		"Flags accepted:\n"
		"\n"
		"  -h         Show help information and exit\n"
		"  -l         Shows a bit more information: CCD with the thread number\n"
		"             and GCD and optimal CCD with the PCIe bus ID\n"
		"\n"
	);

	fprintf( stderr,
		"Meaning of the output:\n"
		"\n"
		"  MPI:       Rank of the MPI process\n"
		"  OMP:       OpenMP thread number\n"
		"  HWT:       Hardware thread\n"
		"  RT_GPU_ID: HIP runtime GPU ID, a local ID, a series starting from 0 for\n"
		"             each process.\n"
		"  GPU_ID:    Global GPU ID, but can become local to the process depending\n"
		"             on how Slurm is used.\n"
		"  Bus_ID:    PCIe bus ID and the only truly reliable way to identify a\n"
		"             physical GPU.\n"
		"\n"
	);

#if defined( BARDPEAK )
	fprintf( stderr,
		"Hardware mapping:\n"
		"\n"
		"  CPU die 0 providing HWT 000-007 and 064-071 to GPU die 4 with Bus_ID d1\n"
		"  CPU die 1 providing HWT 008-015 and 072-079 to GPU die 5 with Bus_ID d6\n"
		"  CPU die 2 providing HWT 016-023 and 080-087 to GPU die 2 with Bus_ID c9\n"
		"  CPU die 3 providing HWT 024-031 and 088-095 to GPU die 3 with Bus_ID ce\n"
		"  CPU die 4 providing HWT 032-039 and 096-103 to GPU die 6 with Bus_ID d9\n"
		"  CPU die 5 providing HWT 040-047 and 104-111 to GPU die 7 with Bus_ID de\n"
		"  CPU die 6 providing HWT 048-055 and 112-119 to GPU die 0 with Bus_ID c1\n"
		"  CPU die 7 providing HWT 056-063 and 120-127 to GPU die 1 with Bus_ID c6\n"
		"\n"
		"  GPU die 0 with Bus_ID c1 to CPU die 6 providing HWT 048-055 and 112-119\n"
		"  GPU die 1 with Bus_ID c6 to CPU die 7 providing HWT 056-063 and 120-127\n"
		"  GPU die 2 with Bus_ID c9 to CPU die 2 providing HWT 016-023 and 080-087\n"
		"  GPU die 3 with Bus_ID ce to CPU die 3 providing HWT 024-031 and 088-095\n"
		"  GPU die 4 with Bus_ID d1 to CPU die 0 providing HWT 000-007 and 064-071\n"
		"  GPU die 5 with Bus_ID d6 to CPU die 1 providing HWT 008-015 and 072-079\n"
		"  GPU die 6 with Bus_ID d9 to CPU die 4 providing HWT 032-039 and 096-103\n"
		"  GPU die 7 with Bus_ID de to CPU die 5 providing HWT 040-047 and 104-111\n"
        "\n"
	);
#endif

	fflush( stderr );

}



//******************************************************************************
//
// get_args( argc, argv, int argc, char **argv, int mpi_myrank,
//		     unsigned int *show_optimap
//
// Gets the input arguments.
//
// Arguments:
//  * argc: Argument count from the main function
//  * argv: Argument values from the main function
//  * mpi_myrank: MPI rank to ensure that help is printed only once.
//    Since in a heterogeneous program some program arguments may only
//    be given for the second instance, we cannot avoid that other error
//    messages will be printed once for each MPI rank in the job component.
//  * show_optimap: On return nonzero if -l is specified, zero otherwise.
//

void get_args( int argc, char **argv, int mpi_myrank,
		       unsigned int *show_optimap ) {

	char *exe_name;

	// Make sure we always return initialised variables, whatever happens.
	*show_optimap = 0;

	// Remove the program name
	exe_name = basename( *argv++ );
	argc--;

	while ( argc-- ) {

		if ( strcmp( *argv, "-h") == 0 ) {
			if ( mpi_myrank == 0 ) print_help( exe_name );
			exit( EXIT_SUCCESS );
		} else if ( strcmp( *argv, "-l") == 0 ) {
			*show_optimap = 1;
		} else {
			fprintf( stderr, "%s: Illegal flag found: %s\n", exe_name, *argv);
			exit( EXIT_WRONG_ARGUMENT );
		}

		argv++;

	}

	return;

}


//******************************************************************************
//
// int get_GCD( const char *busid, const char * const busid_map )
//
// Arguments:
//  * busid (input): The bus ID of the GCD
//  * busid_map (input): Mapping of number of the GCD (index) to the bus ID.
//
// Return value: The GCD number of -1
//

int get_GCD( const char *busid, const char * const busid_map[] ) {

    int GCD = 0;

    while ( ( GCD < MAXGPUS ) && ( strcmp( busid, busid_map[GCD] ) != 0 ) ) GCD++;

    return ( GCD < MAXGPUS ? GCD : -1);

} // end function map_gpu




//******************************************************************************
//
// Main program
//

int main(int argc, char *argv[]){

	unsigned int show_optimap;

	// Initialize MPI

	MPI_Init(&argc, &argv);

	int size;
	MPI_Comm_size( MPI_COMM_WORLD, &size );

	int rank;
	MPI_Comm_rank( MPI_COMM_WORLD, &rank );

	//
	// Interpret the command line arguments
    //

    get_args( argc, argv, rank, &show_optimap );

	//
	// Data gathering
	//

	// - Name of the node (through MPI function rather than the system library gethostname).
	char name[MPI_MAX_PROCESSOR_NAME];
	int resultlength;
	MPI_Get_processor_name( name, &resultlength );

	// - If ROCR_VISIBLE_DEVICES is set, capture visible GPUs
    const char* gpu_id_list; 
    const char* rocr_visible_devices = getenv( "ROCR_VISIBLE_DEVICES" );
    if ( rocr_visible_devices == NULL ) {
        gpu_id_list = "N/A";
    } else {
        gpu_id_list = rocr_visible_devices;
    }

	// - Find how many GPUs HIP runtime says are available
	int num_devices = 0;
    if ( hipGetDeviceCount( &num_devices ) != hipSuccess ) num_devices = 0;                                                               \

    // - Get data on each of the GPUS available to the MPI rank
    char busid_array[MAXGPUS][SINGLE_PCIBUSID_STRLEN];

	for( int i=0; i<num_devices; i++ ){ // Loop over the GPUs available to each MPI rank

		hipErrorCheck( hipSetDevice(i) );

		// Get the PCIBusId for each GPU and use it to query for UUID
		hipErrorCheck( hipDeviceGetPCIBusId( busid_array[i], (int) SINGLE_PCIBUSID_STRLEN, i ) );

#ifdef DEBUG
		{
			char temp_busid[65];
			hipErrorCheck( hipDeviceGetPCIBusId( temp_busid, (int) 65, i ) );
			printf( "GPU %d: found Bus ID %s, with longer variable: %s.\n", i, busid_array[i], temp_busid );
		}
#endif

	} // end for


	//
	// Output the results
	//

	int hwthread;
	int thread_id = 0;

	if ( num_devices == 0 ) {
		#pragma omp parallel default(shared) private(hwthread, thread_id)
		{
			thread_id = omp_get_thread_num();
			hwthread = sched_getcpu();

            printf( "MPI %03d - OMP %03d - HWT %03d - Node %s - GPU N/A\n",
                    rank, thread_id, hwthread, name);

		}
	} else {

        std::string busid_list = "";
        std::string rt_gpu_id_list = "";

		// Loop over the GPUs available to each MPI rank
		for(int i=0; i<num_devices; i++){

			// Find the physical number of the GPU from the bus ID.
			int GCD = get_GCD( busid_array[i], busid_map );
			if ( GCD < 0 ) {
				fprintf( stderr, "Unrecognized bus ID '%s' - %s:%d\n", busid_array[i], __FILE__, __LINE__ );
				exit(0);
			}

			// Concatenate per-MPIrank GPU info into strings for print
            if (i > 0) rt_gpu_id_list.append( "," );
            rt_gpu_id_list.append(std::to_string(i));

            //std::string temp_busid( busid_array[i] );

            if (i > 0) busid_list.append(",");
            if ( show_optimap ) {
            	std::string temp_busid( busid_map_values_long[GCD] );
                busid_list.append( temp_busid );
            } else {
            	std::string temp_busid( busid_map_values_short[GCD] );
                busid_list.append( temp_busid );
            }

		}

		#pragma omp parallel default(shared) private(hwthread, thread_id)
		{
            #pragma omp critical
            {
			thread_id = omp_get_thread_num();
			hwthread = sched_getcpu();

            printf("MPI %03d - OMP %03d - HWT %03d - Node %s - RT_GPU_ID %s - GPU_ID %s - Bus_ID %s\n",
                    rank, thread_id, hwthread, name, rt_gpu_id_list.c_str(), gpu_id_list, busid_list.c_str());
           }
		}
	}

	MPI_Finalize();

	return 0;
}

