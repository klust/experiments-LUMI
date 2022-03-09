#! /bin/bash

for myfile in $(/bin/ls -1 *.out)
do
    if ! $(grep -q 'Performance:' $myfile)
    then
    	jobnumber=${myfile##*-}
    	jobnumber=${jobnumber%.out}
    	echo "-   Job $jobnumber (output file $myfile) did not finish correctly."
    	nodelist="$(sacct -j $jobnumber -X --format 'NodeList%50' | grep nid | sed -e 's/ *//')"
    	echo "    -   Nodelist: $nodelist"
    	batchnode="$(sacct -j ${jobnumber}.batch --format 'NodeList%50' | grep nid | sed -e 's/ *//')"
    	echo "    -   Batch script on $batchnode"
    	if $(grep -q 'MPIDI_OFI_' $myfile)
    	then
    		echo "    -   MPIDI_OFI_ error message found."
    	fi
    	if $(grep -q 'Node failure on' $myfile)
    	then
    		nodes=$(awk '/Node failure/ {print $6}' $myfile)
    		echo "    -   Node failure error message found for node(s) " $nodes
    	fi
    fi
done
