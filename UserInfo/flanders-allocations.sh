#! /bin/bash
#lumi-allocations --lust -p project_465000074,project_465000314,project_465000315,project_465000323,project_465000316,project_465000328,project_465000330

project_list=$(lumi-ldap-projectlist | grep "VLAAMS SUPERCOMPUTER CENTRUM" | sed -e 's|^\(project_[0-9]\{9\}\):.*|\1|' | paste -s -d ',')
lumi-allocations --lust -p $project_list
