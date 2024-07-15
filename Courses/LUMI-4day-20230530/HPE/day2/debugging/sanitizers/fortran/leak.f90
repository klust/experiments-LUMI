program leak
  implicit none

  integer, dimension(:), pointer :: array


  allocate(array(100))

end program leak
