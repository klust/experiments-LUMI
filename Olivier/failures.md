# Failures

## First test run

476048 bound_sim30   18/12 4:14
476032 unbound_sim25 18/12 4:14
475999 bound_sim17   18/12 09:01
475941 bound_sim12   18/12 09:34
475858 bound_sim6    18/12 09:58
475845 bound_sim5    18/12 11:16
476079 bound_sim39   18/12 13:08
476039 unbound_sim27 19/12 08:15
476049 unbound_sim30 19/12 08:15

## Test run on 2022-03-09

11 jobs out of 250 failed.

7 of them failed with OFI-related errors:
``MPIDI_OFI_handle_cq_error(1059): OFI poll failed (ofi_events.c:1061:MPIDI_OFI_handle_cq_error:Input/output error - transport retry counter exceeded)``

-   Job 858670 (output file slurm-858670.out) did not finish correctly.
    -   Nodelist: nid[001986-001987]
    -   Batch script on nid001986
    -   MPIDI_OFI_ error message found.
    -   Node failure error message found for node(s)  nid001987
-   Job 858679 (output file slurm-858679.out) did not finish correctly.
    -   Nodelist: nid[002014-002015]
    -   Batch script on nid002014
    -   MPIDI_OFI_ error message found.
    -   Node failure error message found for node(s)  nid002015
-   Job 858684 (output file slurm-858684.out) did not finish correctly.
    -   Nodelist: nid[001995-001996]
    -   Batch script on nid001995
    -   MPIDI_OFI_ error message found.
    -   Node failure error message found for node(s)  nid001996
-   Job 858760 (output file slurm-858760.out) did not finish correctly.
    -   Nodelist: nid[001744-001745]
    -   Batch script on nid001744
    -   MPIDI_OFI_ error message found.
    -   Node failure error message found for node(s)  nid001745
-   Job 858803 (output file slurm-858803.out) did not finish correctly.
    -   Nodelist: nid[001705-001706]
    -   Batch script on nid001705
    -   MPIDI_OFI_ error message found.
    -   Node failure error message found for node(s)  nid001706
-   Job 859749 (output file slurm-859749.out) did not finish correctly.
    -   Nodelist: nid[002024-002025]
    -   Batch script on nid002024
    -   MPIDI_OFI_ error message found.
    -   Node failure error message found for node(s)  nid002025
-   Job 859892 (output file slurm-859892.out) did not finish correctly.
    -   Nodelist: nid[002200-002201]
    -   Batch script on nid002200
    -   MPIDI_OFI_ error message found.
    -   Node failure error message found for node(s)  nid002201

4 jobs failed without any warning at all in the Slurm output file.

-   Job 858678 (output file slurm-858678.out) did not finish correctly.
    -   Nodelist: nid[001999-002000]
    -   Batch script on nid001999
-   Job 858688 (output file slurm-858688.out) did not finish correctly.
    -   Nodelist: nid[001159-001160]
    -   Batch script on nid001159
-   Job 858730 (output file slurm-858730.out) did not finish correctly.
    -   Nodelist: nid[001414-001415]
    -   Batch script on nid001414
-   Job 858805 (output file slurm-858805.out) did not finish correctly.
    -   Nodelist: nid[001696-001697]
    -   Batch script on nid001696
