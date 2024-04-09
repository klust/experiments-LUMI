#include <assert.h>
#include <omp.h>
#include <omp-tools.h>
#include <stdlib.h>

static int                  has_schedule = 0;
static int                  initialized = 0;
static ompt_finalize_tool_t finalize_tool;

void
callback_ompt_work( ompt_work_t           work_type,
                    ompt_scope_endpoint_t endpoint,
                    ompt_data_t*          parallel_data,
                    ompt_data_t*          task_data,
                    uint64_t              count,
                    const void*           codeptr_ra )
{
    switch ( work_type )
    {
        case ompt_work_loop_static:
        case ompt_work_loop_dynamic:
        case ompt_work_loop_guided:
        case ompt_work_loop_other:
            has_schedule = 1;
            break;
        default:
            break;
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

    /* Do not check and abort if callbacks cannot be registered as some runtimes may not
     * return ompt_set_always or ompt_set_sometimes_registered. In these cases, we still
     * want to try to find out if we may encounter a certain bug to prepare for users enabling
     * the callbacks anyway */
    set_cb( ompt_callback_work, ( ompt_callback_t )&callback_ompt_work );

    initialized = 1;
    return 1; /* non-zero indicates success for OMPT runtime. */
}

static void
ompt_finalize( ompt_data_t* tool_data )
{
    if ( initialized == 1 )
    {
        assert( has_schedule && "Tool got initialized and finalized but no loop schedule was provided." );
        _Exit( 0 ); /* Tool got initialized and finalized. */
    }
}

ompt_start_tool_result_t*
ompt_start_tool( unsigned int omp_version,
                 const char*  runtime_version )
{
    static ompt_start_tool_result_t ompt_start_tool_result = { &ompt_initialize,
                                                               &ompt_finalize,
                                                               ompt_data_none };
    return &ompt_start_tool_result;
}

void foo( int num )
{
}

int
main( void )
{
#pragma omp parallel for schedule(static)
    for ( unsigned i = 0; i < 100; ++i )
    {
        foo( omp_get_thread_num() );
    }

#pragma omp parallel for schedule(dynamic)
    for ( unsigned i = 0; i < 100; ++i )
    {
	foo( omp_get_thread_num() );
    }

#pragma omp parallel for schedule(guided)
    for ( unsigned i = 0; i < 100; ++i )
    {
	foo( omp_get_thread_num() );
    }

    return 1;
}

