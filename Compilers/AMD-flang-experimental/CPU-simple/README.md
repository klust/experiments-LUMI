# Some simple CPU compiler tests

## leapfrog.f90

Source: [GitHub marblestation/benchmark-leapfrog](https://github.com/marblestation/benchmark-leapfrog)

```bash
amdclang -O2 leapfrog.f90 -o leapfrog.x
```

Does not yet work:

```bash
amdclang -O2 -mcpu=znver3 leapfrog.f90 -o leapfrog.x
```

