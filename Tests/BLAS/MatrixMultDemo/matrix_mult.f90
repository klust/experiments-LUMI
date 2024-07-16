program demo_mat_mult

    use f95_precision, only: wp => dp
    use blas95, only: gemm

    implicit none

    integer, parameter :: default_size = 1000
    integer, parameter :: ijk = 1, jik = 2, ikj = 3, jki = 4, kij = 5, kji = 6, &
   &                      f95 = 7, blas = 8
    character(len=*), parameter :: outputformat = '(A12,2X,F8.3,2X,F8.3)'

    real :: flops

    real(wp), allocatable :: A(:,:), B(:,:), C(:,:)
    integer :: size
    integer :: i, j, k
    integer(kind=8) :: start_walltime, end_walltime
    integer(kind=8) :: clockcountrate
    real, dimension(8) :: walltime
    integer :: nargs
    character(len=32) :: arg_buf

    write(*,'(A)') 'Matrix multiplication demo, multiplying two square matrices using:'
    write(*,'(A)') ' - Naive sequential code: 6 possible orders of the three loops'
    write(*,'(A)') ' - F95 MATMULT function'
    write(*,'(A)') ' - BLAS, with the number of cores used determined by environment variables (_p executables, '
    write(*,'(A)') '   also compiled with OpenMP enabled) or on a single core (_s executables)'
    write(*,'(A)') 'The program takes one optional command line argument: the matrix size.'
    write(*,'(A)') ''

    ! Read the optional command line argument:number of matrix rows
    nargs = command_argument_count()
    if ( nargs > 0 ) then
        call get_command_argument( 1, arg_buf )
        read(arg_buf,*) size
    else
        size = default_size
    end if

    write(*,'(A,I0)') 'Selected matrix size: ', size
    write(*,'(A)')    ''

    ! Allocate the arrays
    allocate( A(size,size) )
    allocate( B(size,size) )
    allocate( C(size,size) )

    ! Fill up the matrices A and B
    do j = 1, size
        do i = 1, size
            A(i,j) = dsin( (1.D0 * (i+j)) / size * 3.14D0 )
            B(i,j) = dcos( (1.D0 * (i-j)) / size * 3.14D0 )
        end do
    end do

    !######################################################
    !
    ! The actual computations
    !

    ! Print the header of the results
    write(*,*)
    write(*,'(A,I5,A,I5,A,F8.2,A)') 'Matrix size: ', size, '*', size, ', ', (8.*size*size) / (1024.0*1024.0), 'MB per array'
    write(*,*)
    write(*,'(A)')                   "Variant       time (s)    Gflops"
    write(*,'(A)')                   "--------------------------------"

    ! Regular order: i-j-k
    call system_clock( start_walltime, clockcountrate )
    do i = 1, size
        do j = 1, size
            C(i,j) = 0.D0
            do k = 1, size
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
    call system_clock( end_walltime, clockcountrate )
    walltime(ijk) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "ijk-variant: ", walltime(ijk), &
    & flops( size, walltime(ijk) ) / 1.D9


    ! Regular order: j-i-k
    call system_clock( start_walltime, clockcountrate )
    do j = 1, size
        do i = 1, size
            C(i,j) = 0.D0
            do k = 1, size
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
    call system_clock( end_walltime, clockcountrate )
    walltime(jik) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "jik-variant: ", walltime(jik), &
    & flops( size, walltime(jik) ) / 1.D9


    ! Order: i-k-j
    call system_clock( start_walltime, clockcountrate )
    do i = 1, size
        do j = 1, size
            C(i,j) = 0.D0
        end do
        do k = 1, size
            do j = 1, size
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
    call system_clock( end_walltime, clockcountrate )
    walltime(ikj) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "ikj-variant: ", walltime(ikj), &
    & flops( size, walltime(ikj) ) / 1.D9


    ! Order: j-k-i
    call system_clock( start_walltime, clockcountrate )
    do j = 1, size
        do i = 1, size
            C(i,j) = 0.D0
        end do
        do k = 1, size
            do i = 1, size
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
    call system_clock( end_walltime, clockcountrate )
    walltime(jki) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "jki-variant: ", walltime(jki), &
    & flops( size, walltime(jki) ) / 1.D9


    ! Order: k-i-j
    call system_clock( start_walltime, clockcountrate )
    do i = 1, size
        do j = 1, size
            C(i,j) = 0.D0
        end do
    end do
    do k = 1, size
        do i = 1, size
            do j = 1, size
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
    call system_clock( end_walltime, clockcountrate )
    walltime(kij) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "kij-variant: ", walltime(kij), &
    & flops( size, walltime(kij) ) / 1.D9


    ! Order: k-j-i
    call system_clock( start_walltime, clockcountrate )
    do j = 1, size
        do i = 1, size
            C(i,j) = 0.D0
        end do
    end do
    do k = 1, size
        do j = 1, size
            do i = 1, size
                C(i,j) = C(i,j) + A(i,k) * B(k,j)
            end do
        end do
    end do
    call system_clock( end_walltime, clockcountrate )
    walltime(kji) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "kji-variant: ", walltime(kji), &
    & flops( size, walltime(kji) ) / 1.D9


    ! f95 matmult function
    call system_clock( start_walltime, clockcountrate )
    C = matmul( A, B )
    call system_clock( end_walltime, clockcountrate )
    walltime(f95) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "f95 MATMULT: ", walltime(f95), &
    & flops( size, walltime(f95) ) / 1.D9


    ! BLAS-call
    call system_clock( start_walltime, clockcountrate )
    call GEMM( A, B, C, 'N', 'N', 1.D0, 1.D0 )
    call system_clock( end_walltime, clockcountrate )
    walltime(blas) = real(end_walltime - start_walltime) / real(clockcountrate)

    write(*,outputformat) "BLAS:        ", walltime(blas), &
    & flops( size, walltime(blas) ) / 1.D9

end program demo_mat_mult


function flops( size, time )

    implicit none

    real :: flops
    integer, intent(in) :: size
    real, intent(in)    :: time

    flops = 2. * real(size) * real(size) * real(size) / time

end function flops
