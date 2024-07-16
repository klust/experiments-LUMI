! Multithreaded BLAS DGEMM benchmark.
!
! This program takes command line arguments.
!
! * The first argument is the matrix size. If no arguments are given, a default
!   set in the constant nrows_devault in the code is used.
! * The second and other arguments are the number of threads to be used. There
!   is always a run on a single thread to compute speedups.
!   If there is only one argument (or none at all), the DGEMM is run on 1, 2,
!   ... up to the number of processors threads.
!
program demo_mat_mult

    use f95_precision, only: wp => dp
    use blas95, only: gemm

    implicit none

    integer :: blas_get_num_procs

    integer, parameter :: nrows_default = 1000
    integer, parameter :: arglen = 32
#ifdef METHOD
    character(len=8), parameter :: method = METHOD
#else
    character(len=8), parameter :: method = "OpenBLAS"
#endif

    character(len=arglen) :: arg_buf
    integer               :: nargs
    integer               :: nrows
    integer               :: nproc_choices
    integer, allocatable  :: nprocs(:)
    integer               :: num_procs
    integer               :: prev_procs_used

    real(wp), allocatable :: A(:,:), B(:,:), C(:,:)
    integer               :: i, j
    integer               :: cproc

    integer(kind=8)       :: start_walltime, end_walltime
    integer(kind=8)       :: clockcountrate
    real                  :: start_cputime, end_cputime
    real, allocatable     :: walltime(:), cputime(:)
    integer, allocatable  :: new_proc_conf(:)
    real :: flops

    ! Print some information
    write(*, '(A)')      'Matrix-matrix multiplication with BLAS.'
    write(*, '(A,I0,A)') '+ First argument: matrix size. Without arguments the default ', nrows_default, ' is used.'
    write(*, '(A)')      '+ Second and further argument: Number of cores to use (multiple computations possible).'
    write(*, '(A)')      '  A computation on a single core is always included as a reference.'
    write(*, '(A)')      ''

    ! Get the number of processors
    num_procs = blas_get_num_procs()

    ! Read the two command line arguments: number of matrix rows and number of threads
    nargs = command_argument_count()

    if ( nargs == 0 ) then
        nrows = nrows_default
    else
        call get_command_argument( 1, arg_buf )
        read(arg_buf,*) nrows
    end if

    ! Print information about the matrix size
    write(*,'(A,I5,A,I5,A,F8.2,A)') 'Matrix size: ', nrows, '*', nrows, ', ', &
        & (8.*nrows*nrows) / (1024.0*1024.0), 'MB per array'
    write(*,'(A)') ""

    nproc_choices = nargs
    if ( nargs <= 1 ) nproc_choices = num_procs
    allocate( nprocs(nproc_choices) )
    nprocs(1) = 1

    if ( nargs <= 1 ) then
        do cproc = 1, nproc_choices
          nprocs(cproc) = cproc
        end do
    else
        do cproc = 2, nproc_choices
          call get_command_argument( cproc, arg_buf )
          read(arg_buf,*) nprocs(cproc)
        end do
    end if

    ! Allocate the arrays
    allocate( A(nrows, nrows) )
    allocate( B(nrows, nrows) )
    allocate( C(nrows, nrows) )
    allocate( walltime(nproc_choices) )
    allocate( cputime(nproc_choices) )
    allocate( new_proc_conf(nproc_choices) )

    ! Fill up the matrices A and B
!$omp parallel do
    do j = 1, nrows
        do i = 1, nrows
            A(i,j) = dsin( (1.D0 * (i+j)) / nrows * 3.14D0 )
            B(i,j) = dcos( (1.D0 * (i-j)) / nrows * 3.14D0 )
        end do
    end do
!$omp end parallel do

    ! BLAS-call
    prev_procs_used = 0
    do cproc = 1, nproc_choices
        if ( nprocs(cproc) /= prev_procs_used ) then
            call blas_set_num_threads( nprocs(cproc) )
            prev_procs_used = nprocs(cproc)
            new_proc_conf(cproc) = 1
        else
            new_proc_conf(cproc) = 0
        endif
        write(*, '(A,I0,A)') 'Computing on ', nprocs(cproc), ' core(s).'
        call cpu_time( start_cputime )
        call system_clock( start_walltime, clockcountrate )
        call GEMM( A, B, C, 'N', 'N', 1.D0, 1.D0 )
        call system_clock( end_walltime, clockcountrate )
        call cpu_time( end_cputime )
        walltime(cproc) = real(end_walltime - start_walltime) / real(clockcountrate)
        cputime(cproc)  = end_cputime - start_cputime
    end do

    ! Print the results
    write(*,'(A)') ""
    write(*,'(A,I5,A,I5,A,F8.2,A)') '### Matrix size: ', nrows, '*', nrows, ', ', &
        & (8.*nrows*nrows) / (1024.0*1024.0), 'MB per array'
    write(*,'(A)') "### "
    write(*,'(A)') "### Variant   nthreads  time (s)    Gflops  speedup  efficiency (%)  CPUtime (s)  new conf"
    write(*,'(A)') "### --------------------------------------------------------------------------------------"
    do cproc = 1, nproc_choices
        write(*,'(A4,A8,2X,I8,2X,F8.3,2X,F8.3,2X,F7.3,2X,F14.3,2X,F11.3,2X,I8)') &
            & "### ", method, nprocs(cproc), &
            & walltime( cproc ), flops( nrows, walltime( cproc ) ) / 1.D9, &
            & walltime(1) / walltime(cproc), &
            & 100D0 * walltime(1) / ( nprocs(cproc) * walltime(cproc) ), &
            & cputime( cproc ), new_proc_conf(cproc)
    end do
    write(*,*)

    write(*, '(A)') 'CSV Variant,   nrows, nthreads, "time (s)",   Gflops, speedup, ' // &
                  & '"efficiency (%)", "CPU time (s)", "new conf"'
    do cproc = 1, nproc_choices
        write(*,'(A4, A8,", ",I6,", ",I8,", ",F10.4,", ",F8.4,", ",F7.3,", ",F16.4,", ",F14.4,", ",I10)') &
            & "CSV ", method, nrows, nprocs(cproc), &
            & walltime( cproc ), flops( nrows, walltime( cproc ) ) / 1.D9, &
            & walltime(1) / walltime(cproc), &
            & 100D0 * walltime(1) / ( nprocs(cproc) * walltime(cproc) ), &
            & cputime( cproc ), new_proc_conf(cproc)
    end do
    write(*,*)


end program


function flops( nrows, time )

    implicit none

    real :: flops
    integer, intent(in) :: nrows
    real, intent(in)    :: time

    flops = 2. * real(nrows) * real(nrows) * real(nrows) / time

end function
