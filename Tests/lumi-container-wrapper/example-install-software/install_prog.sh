cp fftw.cpp $CW_INSTALLATION_PATH
cd $CW_INSTALLATION_PATH
export CPATH="$CPATH:$env_root/include"
g++ -lfftw3 -L $env_root/lib fftw.cpp -o fftw_prog
