module prk

  contains

      function prk_get_wtime() result(t)

        use, intrinsic :: iso_fortran_env

        implicit none

        real(kind=REAL64) ::  t
        integer(kind=INT64) :: c, r

        call system_clock(count = c, count_rate = r)

        t = real(c,REAL64) / real(r,REAL64)

      end function prk_get_wtime

end module prk



program main

  use, intrinsic :: iso_fortran_env
  use prk

  implicit none

  integer :: me, np, p
  integer :: err

  ! problem definition
  integer(kind=INT32) :: iterations
  integer(kind=INT64) :: length, offset
  integer(kind=INT32) :: co_iterations[*]
  integer(kind=INT64) :: co_length[*]
  real(kind=REAL64), allocatable ::  A(:)[:]
  real(kind=REAL64), allocatable ::  B(:)[:]
  real(kind=REAL64), allocatable ::  C(:)[:]
  real(kind=REAL64) :: scalar
  integer(kind=INT64) :: bytes

  ! runtime variables
  integer(kind=INT64) :: i
  integer(kind=INT32) :: k
  real(kind=REAL64) ::  asum, ar, br, cr
  real(kind=REAL64) ::  co_asum[*]
  real(kind=REAL64) ::  t0, t1, nstream_time, avgtime
  real(kind=REAL64), parameter ::  epsilon=1.D-8

  me = this_image()

  np = num_images()


  ! ********************************************************************
  ! read and test input parameters
  ! ********************************************************************



  if (me.eq.1) then

    write(*,'(a25)') 'Parallel Research Kernels'

    write(*,'(a48)') 'Fortran coarray STREAM triad: A = B + scalar * C'

    iterations = 10
    length = 1000*1000*10
    offset = 0

    write(*,'(a23,i12)') 'Number of images     = ', np
    write(*,'(a23,i12)') 'Number of iterations = ', iterations
    write(*,'(a23,i12)') 'Vector length        = ', length
    write(*,'(a23,i12)') 'Offset               = ', offset


    ! co_broadcast is 2018 and not available in all coarray implementations

    do p=1,np
      co_iterations[p] = iterations
      co_length[p]     = length
    enddo

  endif

  sync all

  if (me.ne.1) then
    ! copy broadcast inputs to local variables
    iterations = co_iterations[this_image()]
    length     = co_length[this_image()]
  endif

  ! ********************************************************************
  ! ** Allocate space and perform the computation
  ! ********************************************************************

  allocate( A(length)[*], B(length)[*], C(length)[*], stat=err)

  if (err .ne. 0) then
    write(*,'(a,i3)') 'allocation returned ',err
    error stop 1
  endif

  do concurrent (i=1:length)
    A(i) = 0
    B(i) = 2
    C(i) = 2
  enddo

  sync all

  scalar = 3

  t0 = 0

  do k=0,iterations

    if (k.eq.1) then
      sync all ! barrier
      t0 = prk_get_wtime()
    endif

    do concurrent (i=1:length)
      A(i) = A(i) + B(i) + scalar * C(i)
    enddo

  enddo ! iterations

  sync all

  t1 = prk_get_wtime()

  nstream_time = t1 - t0

  ! ********************************************************************
  ! ** Analyze and output results.
  ! ********************************************************************

  ar  = 0
  br  = 2
  cr  = 2
  do k=0,iterations
      ar = ar + br + scalar * cr;
  enddo

  asum = 0
  do concurrent (i=1:length)
    asum = asum + abs(A(i)-ar)
  enddo

  ! reduction via gather
  co_asum[me] = asum
  sync all
  asum = 0
  if (me.eq.1) then
    do p=1,np
      asum = asum + co_asum[p]
    enddo
  endif

  deallocate( A,B,C )

  if (abs(asum) .gt. epsilon) then
    if (me.eq.1) then
      write(*,'(a35)') 'Failed Validation on output array'
      write(*,'(a30,f30.15)') '       Expected value: ', ar
      write(*,'(a30,f30.15)') '       Observed value: ', A(1)
      write(*,'(a35)')  'ERROR: solution did not validate'
      error stop 1
    endif
  else
    if (me.eq.1) write(*,'(a17)') 'Solution validates'
    avgtime = nstream_time/iterations;
    bytes = 4 * np * length * storage_size(A)/8
    if (me.eq.1) then
      write(*,'(a12,f15.3,1x,a12,e15.6)')    &
              'Rate (MB/s): ', 1.d-6*bytes/avgtime, &
              'Avg time (s): ', avgtime
    endif
  endif

end program main
