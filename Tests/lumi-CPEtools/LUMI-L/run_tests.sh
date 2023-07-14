#! /usr/bin/bash
#
# Run all tests with lumi-CPETools on the login node.
#

echo "Read from the environment: LUMI_STACK_VERSION = ${LUMI_STACK_VERSION}, EBVERSIONLUMIMINCPETOOLS = ${EBVERSIONLUMIMINCPETOOLS}."
stack_version=${LUMI_STACK_VERSION:-'22.12'}
CPE_version=${EBVERSIONLUMIMINCPETOOLS:-'1.1-cpeCray-22.12'}
CPE_version=${CPE_version%-cpe*}
echo -e "Running with lumi-CPEtools/${CPE_version}-cpe*-${stack_version}\n"

module load LUMI/$stack_version partition/L

for prgenv in GNU Cray AOCC
do

    echo -e "\n\nTesting cpe${prgenv} version\n\n"
    
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    echo -e "\nserial_check:\n"
    serial_check -r
    
    echo -e "\nomp_check:\n"
    OMP_NUM_THREADS=4 omp_check -r
    
    echo -e "\nmpi_check:\n"
    mpi_check -r
    
    echo -e "\nhybrid_check:\n"
    OMP_NUM_THREADS=4 hybrid_check -r
    
done
