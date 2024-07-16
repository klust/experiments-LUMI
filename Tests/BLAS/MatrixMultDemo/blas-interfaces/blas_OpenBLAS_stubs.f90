! Stubs to use the OpenBLAS library
!

function blas_get_num_procs()

    implicit none

    integer :: blas_get_num_procs
    integer :: openblas_get_num_procs

    blas_get_num_procs = openblas_get_num_procs()

    return

end function blas_get_num_procs


subroutine blas_set_num_threads( num_procs )

    implicit none

    integer :: num_procs

    call openblas_set_num_threads( num_procs )

end subroutine blas_set_num_threads
