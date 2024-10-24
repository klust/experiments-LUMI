!##############################################################################
! The following lines would belong to merge.f90

program test

  implicit none
  real(kind=8) :: potato

  call random_number(potato)


  ! This works.
  write(105, '(a)') merge("D3(op)-ATM", "D3(op)    ", abs(potato) > 0)

  ! This fails.
  write(105, '(a)') trim( merge("D3(op)-ATM", "D3(op)    ", abs(potato) > 0) )
end program test

!##############################################################################
