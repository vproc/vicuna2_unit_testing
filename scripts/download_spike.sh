#!/bin/bash

cd ../toolchain

#Build GCC
echo "Downloading Spike"
if [ -d $PWD/riscv-isa-sim ]; then
    echo "Spike source already downloaded. Cleaning Up."
    cd riscv-isa-sim
    rm -r build
else
    git clone https://github.com/riscv-software-src/riscv-isa-sim.git
    cd riscv-isa-sim
    git reset --hard 3f79e3b7ded80d9ef0e722126b3765207e010711 # Spike commit needed for RISCV Tests
fi


mkdir build
cd build 
../configure --prefix=$PWD/../riscv
make -j$(nproc)
make install

