#include <omp-tools.h>
#include <omp.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>


static int                  initialized          = 0;
static int                  parallel_end_reached = 0;
static ompt_finalize_tool_t finalize_tool;

void
callback_sync_region( ompt_sync_region_t    kind,
                      ompt_scope_endpoint_t endpoint,
                      ompt_data_t*          parallel_data,
                      ompt_data_t*          task_data,
                      const void*           codeptr_ra )
{
    if ( endpoint == ompt_scope_end )
    {
        assert( parallel_data == NULL && "Parallel data should be NULL for end of parallel, but was not" );
	parallel_end_reached = 1;
    }
}

static int
ompt_initialize( ompt_function_lookup_t lookup,
                 int                    initial_device_num,
                 ompt_data_t*           tool_data )
{
    ompt_set_callback_t set_cb = ( ompt_set_callback_t )lookup( "ompt_set_callback" );
    assert( set_cb && "Tool got initialized but lookup of runtime-entry-point ompt_set_callback failed." );
    
    finalize_tool = ( ompt_finalize_tool_t )lookup( "ompt_finalize_tool" );
    assert( finalize_tool && "Tool got initialized but lookup of runtime-entry-point ompt_finalize_tool failed." );
    
    ompt_set_result_t result;

    /* Do not abort if callbacks may only sometimes report events. In these cases, we still
     * want to try to find out if we may encounter a certain bug to prepare for users enabling
     * the callbacks anyway */
    result = set_cb( ompt_callback_sync_region, ( ompt_callback_t )&callback_sync_region );
    /* In the cases where the runtimes fails to register the callback at all, set ws_loop_end_reached,
     * to let this test pass. The activation failure is then handled during OMPT adapter initialization. */
    if( result == ompt_set_error || result == ompt_set_never || result == ompt_set_impossible )
    {
        set_cb( ompt_callback_sync_region, NULL );
    }

    initialized = 1;
    return 1; /* non-zero indicates success for OMPT runtime. */
}

static void
ompt_finalize( ompt_data_t* tool_data )
{
    if ( initialized == 1 )
    {
	assert( parallel_end_reached && "Parallel end not reached" );
        _Exit( 0 ); /* Tool got initialized and finalized. */
    }
}

ompt_start_tool_result_t*
ompt_start_tool( unsigned int omp_version,                           /* == _OPENMP */
                 const char*  runtime_version )
{
    static ompt_start_tool_result_t ompt_start_tool_result = { &ompt_initialize,
                                                               &ompt_finalize,
                                                               ompt_data_none };
    return &ompt_start_tool_result;
}

int
foo( int i )
{
    printf("foo()\n");
    return i;
}

int
main( void )
{
#pragma omp parallel
    {
        foo( omp_get_thread_num() );
    }
    finalize_tool();
    return 1;
}

