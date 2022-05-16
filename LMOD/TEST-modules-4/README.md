# Demo Lmod problem when a module uses its own directory in prepend_path/append_path of MODULEPATH

## Instructions

To initialise Lmod for demonstrating this problem one can simply go to the directory 
with the `source_to_init.sh` script and source it there

```bash
source source_to_init.sh
```

Next the problem can be illustrated easily by simply sourcing the `demo_bug_or_feature.sh`
script:

```bash
source demo_bug_or_feature.sh
```

## What happens?

The module `init-cluster/1.0.lua' tries to re-order the MODULEPATH by doing a `prepend_path`
to `MODULEPATH` with its own directory (beside also adding the `modules/Stacks` subdirectory
to MODULEPATH. Though this may seem stupid, one reason why one would consider doing 
this is to always have that `init-cluster/1.0` module at the very front of the 
`MODULEPATH` so that it is displayed first in `module avail`.

The code in `modules/init-mmodules/init-cluster/1.0.lua` that does this can be turned 
on by setting (and exporting) `TRIGGER_BUG` to an arbitrary value (even just empty) 
so that it is easy to see the difference with and without this line in the module file.

Now try the following tests with no modules loaded:

When running with `TRIGGER_BUG` unset one gets:


```
$ module spider Appl1

------------------------------------------------------------------------------------
  Appl1: Appl1/1
------------------------------------------------------------------------------------

    You will need to load all module(s) on any one of the lines below before the "Appl1/1" module is available to load.

      init-cluster/1.0  MyStack/2021
      init-cluster/1.0  MyStack/2022
      
```

which is what we would like two get. There are indeed two different `Appl/1` modules in 
the hierarchy, and the ways to reach the module are shown in the right way.

However, now trigger the bug:

```bash
export TRIGGER_BUG=
```

```
$ module spider Appl1

------------------------------------------------------------------------------------
  Appl1: Appl1/1
------------------------------------------------------------------------------------

    You will need to load all module(s) on any one of the lines below before the "Appl1/1" module is available to load.
    
```

Notice that Lmod fails to detect how the `Appl1` module can be loaded.

The demo also works if `init-cluster/1.0` is loaded.

