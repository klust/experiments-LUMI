# merge function error?

Source: Ticket [#5263](https://rt.lumi-supercomputer.eu/Ticket/Display.html?id=5263).

User claims this is allowed in the Fortran standard while it fails with CCE.

Reproduce:

```bash
module load cpe/24.03
module load PrgEnv-cray

ftn trim_merge.f90
```

Result is a compiler crash.

