# Issues we ran into with SCons

## Use case

Installing SCons as an independent program so that no Python module needs to be 
loaded explicitly to use it. Moreover, we want to encapsulate it as much as possible
so that maybe it may even be used in software installations of Python code that uses
a different Pytho0n.

To enable that encapsulation, we use two tricks:

-   Hard-code the path to the Python interpreter to be used

-   Set the Python search path in the python script with 
    `sys.path.append`.


## Issues

-   In EasyBuild 5, the shebang editing is done after the execution of `postinstallcmds` 
    which is not what one would expect, as you'd hope that `postinstallcmds` is where 
    you can make all final corrections.
    
    It is easy to get around though using
    ``` python
    fix_python_shebang_for = []
    ```
    but it did take a while to figure that out as it is not what one would expect and
    you need to be carefully monitoring what is going on in the trace output.
    
    The solution is also compatible with EasyBuild 4.9, so one can develop a recipe that
    works with both 4.9 and 5.1 for the transition period.
    
    Fixing Python shebangs by default is something that was added in EasyBuild 5.0
    ([PR #3499](https://github.com/easybuilders/easybuild-easyblocks/pull/3499)]. 
    The stupid thing in my view is that it is done AFTER `postinstallcmds` so that
    `postinstallcmds` is no longer the place where you can make final corrections to
    things you don't like in the build. But fortunately there is an easy workaround.
    
-   Issue with the selection of Python. To isolate the issue, we tried a `PythonPackage` 
    build with SCons only.
    
    -   EasyBuild 4:
        ``` python
        local_pyshortver = '3.6'
        req_py_majver = local_pyshortver.split('.')[0]
        req_py_minver = local_pyshortver.split('.')[1]        
        ```
        `req_py_majver` and `rq_py_minver` have to be strings and we couldn't get 
        `max_py_majver` and `max_py_minver` to work with either strings or ints.
        
    -   EasyBuild 5:
        ```python
        local_pyshortver = '3.6'
        req_py_majver = int( local_pyshortver.split('.')[0] )
        req_py_minver = int( local_pyshortver.split('.')[1] )
        max_py_majver = int( local_pyshortver.split('.')[0] )
        max_py_minver = int( local_pyshortver.split('.')[1] )
        ```
        works, but all parameters have to be integers now.
        
    So there is no way to have a solution that works with both EasyBuild 4.9 and 5.1 to have
    a gradual transition. Moreover, you don't get a proper error message about a type 
    error, but just a message that it can't locate a suitable python command.
    
-   It would be good to be able to avoid the auto-generation of `PYTHONPATH`, but this
    is an issue that has been present for longer.
    
-   As we are using the system python here, which is always in the path, 
    