!##############################################################################
! The following lines would belong to parameter.f90

module potatomod

  public :: potato

  integer, parameter :: max_e = 5
  integer, parameter :: max_r = 3

  real(kind=8), parameter :: potato(3,5) = reshape([&
    0.0d0, 0.1d0, 0.2d0, 0.3d0, 0.4d0,&
    0.0d0, 0.1d0, 0.2d0, 0.3d0, 0.4d0,&
    0.0d0, 0.1d0, 0.2d0, 0.3d0, 0.4d0],&
    shape(potato))

end module potatomod



program test

  use potatomod, only : potato
  implicit none

  print*, potato

end program test
!##############################################################################
