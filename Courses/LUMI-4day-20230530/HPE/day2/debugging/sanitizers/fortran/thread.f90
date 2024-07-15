program thread
  implicit none

  integer, dimension(10) :: array
  integer :: i

  array = 2

!$omp parallel do
  do i=1, 10
     array(2) = 4
     print *, i, array(i)
  end do
!$omp end parallel do

end program thread
