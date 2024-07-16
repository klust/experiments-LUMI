program g90_dgemm

    use iso_fortran_env, only: output_unit
    use f95_precision, only: wp => dp
    use blas95, only: gemm

    implicit none

    integer :: blas_get_num_procs

    integer, parameter :: arglen = 32
#if defined( OpenBLAS )
    character(len=10), parameter :: method = "OpenBLAS  "
#elif defined( BLIS )
    character(len=10), parameter :: method = "BLIS      "
#else
    character(len=10), parameter :: method = "Other BLAS"
#endif

    character(len=arglen) :: arg_nrows, arg_nproc
    integer               :: nargs
    integer               :: nrows
    integer               :: nprocs

    real(wp), allocatable :: A(:,:), B(:,:), C(:,:)
    integer               :: i, j

    real            :: start_cputime,  end_cputime
    integer(kind=8) :: start_walltime, end_walltime
    integer(kind=8) :: clockcountrate
    real            :: walltime
    real            :: flops
    integer         :: system_procs

#if defined( OpenBLAS )
    integer         :: openblas_get_num_procs
#elif defined( BLIS )
    integer         :: openblas_get_num_procs
    !integer         :: bli_thread_get_num_threads
#else
    integer         :: blas_get_num_procs
#endif

    ! Get the number of processors
#if defined( OpenBLAS )
    system_procs = openblas_get_num_procs()
#elif defined( BLIS )
    system_procs = openblas_get_num_procs()
    !system_procs = bli_thread_get_num_threads()
#else
    system_procs = blas_get_num_procs()
#endif

    ! Read the two command line arguments: number of matrix rows and number of threads
    nargs = command_argument_count()
    if ( nargs /= 2 ) then
        write(*, '(A)') 'The program needs two arguments: Matrix nrows and number of threads.'
        stop
    end if

    ! Read the two command line arguments: number of matrix rows and number of threads
    call get_command_argument( 1, arg_nrows )
    call get_command_argument( 2, arg_nproc )
    read(arg_nrows,*) nrows
    read(arg_nproc,*) nprocs
    write(output_unit,'(A,I0,A,I0,A)') '## Doing matrix multiplication of matrices of nrows ', nrows, ' on ', nprocs, ' threads.'
    write(output_unit,'(A,F8.2,A)')    '## Memory: ', (8.*nrows*nrows) / (1024.0*1024.0), 'MB per array'
    write(output_unit,'(A,A,A,I0,A)')  '## ', method, ' detected ', system_procs, ' processors in the system.'

    ! Allocate the arrays
    allocate( A(nrows, nrows) )
    allocate( B(nrows, nrows) )
    allocate( C(nrows, nrows) )

    ! Fill up the matrices A and B
!$omp parallel do
    do j = 1, nrows
        do i = 1, nrows
            A(i,j) = dsin( (1.D0 * (i+j)) / nrows * 3.14D0 )
            B(i,j) = dcos( (1.D0 * (i-j)) / nrows * 3.14D0 )
        end do
    end do
!$omp end parallel do

    ! Print the header of the table before starting the actual computations
    write(output_unit,'(A)') "## "
    write(output_unit,'(A)') "## Variant    nrows  mem per mat (MB)  nproc  walltime (s)    Gflops  cputime (s)  load balance (%)"
    write(output_unit,'(A)') "## ------------------------------------------------------------------------------------------------"
    write(output_unit,'(A2,1X,A8,2X,I6,10X,F8.2,5X,I2)', advance="no") &
        & "##", method, nrows, (8.*nrows*nrows) / (1024.0*1024.0), nprocs
    flush(output_unit)

    ! BLAS-call
#if defined( OpenBLAS )
    call openblas_set_num_threads( nprocs )
#elif defined( BLIS )
    call bli_thread_set_num_threads( nprocs )
#else
    call blas_set_num_threads( nprocs )
#endif
    call system_clock( start_walltime, clockcountrate )
    call cpu_time( start_cputime )
    call GEMM( A, B, C, 'N', 'N', 1.D0, 1.D0 )
    call cpu_time( end_cputime )
    call system_clock( end_walltime, clockcountrate )
    walltime = real(end_walltime - start_walltime) / real(clockcountrate)

    ! Print the results
    write(output_unit,'(6X,F8.3,2X,F8.3,2X,F11.3,13X,F5.1)') &
        & walltime, flops( nrows, walltime ) / 1.D9, &
        & end_cputime - start_cputime, &
        & 100E0 * (end_cputime - start_cputime) / (nprocs * walltime)
!    write(output_unit,'(A2,1X,A8,2X,I6,10X,F8.2,5X,I2,6X,F8.3,2X,F8.3,2X,F11.3,13X,F5.1)') &
!        & "##", method, nrows, (8.*nrows*nrows) / (1024.0*1024.0), nprocs , &
!        & walltime, flops( nrows, walltime ) / 1.D9, &
!        & end_cputime - start_cputime, &
!        & 100E0 * (end_cputime - start_cputime) / (nprocs * walltime)

end program


function flops( nrows, time )

    implicit none

    real :: flops
    integer, intent(in) :: nrows
    real, intent(in)    :: time

    flops = 2. * real(nrows) * real(nrows) * real(nrows) / time

end function

