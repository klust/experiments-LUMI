#! /bin/bash
#
# Takes one argument: The name of the process to look for.
#

pname=$1
for pid in $(pgrep "${pname}") ; do 
    [ "${pid}" != "" ] || exit
    echo "PID: ${pid}"
    for tid in \
          $(ps --no-headers -ww -p "${pid}" -L -olwp | sed 's/$/ /' | tr  -d '\n') ; do
        echo -n "Thread ID ${tid}: "
        taskset -cp "${tid}"  # substitute thread id in place of a process id
    done
done
