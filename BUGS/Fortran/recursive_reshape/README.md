# Using a constant being declared in a reshape statement

Source: Ticket [#5263](https://rt.lumi-supercomputer.eu/Ticket/Display.html?id=5263).

User claims this is allowed in the Fortran standard while it fails with CCE.

Case that fails:

```
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
```

compiled with

```bash
module load cpe/24.03
module load PrgEnv-cray

ftn parameter_fail.f90
```

Note that Cray Fortran does produce a proper error message, 

```
  real(kind=8), parameter :: potato(3,5) = reshape([&
                             ^
ftn-1426 ftn: ERROR POTATOMOD, File = parameter_fail.f90, Line = 11, Column = 30
  "POTATO" has been referenced or defined in a prior statement in this scope.  It may not be given the PARAMETER attribute.
```

and then after `explain ftn-1426`:

```
Error : "%s" has been referenced or defined in a prior statement in this
scope.  It may not be given the PARAMETER attribute.

The object being declared has been referenced or defined.  A object must be
given the PARAMETER attribute before being referenced or defined.
```

It looks like "prior use" is actually the `shape(potato)` which appears later in the code?

It does work however without the `parameter` attribute, see `parameter_works1.f90`.
