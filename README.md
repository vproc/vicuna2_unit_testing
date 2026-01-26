# Vicuna2_unit_testing
Unit Testing Framework for Vicuna.  Includes legacy handwritten unit tests, as well as the ChipsAlliance Tests for the V extension

# Getting Started

The repository is composed of two CMake projects.

The first is under '_/build_model_'.  This project builds the verilator model to test.  This folder contains the top level _CMakelist.txt_ file.  It also contains the '_vector_config.cmake_' file, which should be used to change configurations of the vector unit.  

Currently two scalar cores are supported:
<ul>
  <li>[CV32E40X](http://example.com)</li>
  <li>[CV32A60X](http://example.com)</li>
</ul> 
As the interfaces for each core is different, a folder containing the core specific integration _vproc_top.sv_ and _verilator_main.cpp_ are present in the _/build_model_ folder.  Additionally, some core specific simulation functions have been added, and are included in the built model.

The Verilator model CMake project uses the rtl sources in the _/rtl_ folder, which are all added as submodules.  Note that the versions of the scalar cores used in this repository are development forks, as some bug fixes which have been found have not yet been upstreamed.

A model can be built according to the configuration in '_vector_config.cmake_' using the following commands:

```
git submodule update --init --recursive
cd /build_model
mkdir build
cd build
cmake ..
make
```

The second CMake project is located in the '_/build_tests_' folder.  All test sources are located in the '_/test_sources_' folder.  The tests are added to the CTest framework.

Two types of unit tests are currently supported in this repository.
<ul>
  <li>**Legacy Tests** - these are the original handwritten unit tests used for Vicuna1.0, along with additional tests written in this style for floating point operations</li>
  <li>**ChipsAlliance Vector Tests** - these are generated using the generator from ChipsAlliance under the [riscv-vector-tests]([http://example.com](https://github.com/chipsalliance/riscv-vector-tests) repo</li>
</ul> 

The type of test compiled and run can be changed with the flag _-DLegacy=ON_.  The default is to run the ChipsAlliance tests.

The ChipsAlliance test generator depends on the vector register length.  This parameter is imported from the '_vector_config.cmake_' file.  If it is changed, a new set of tests AND verilator model must be generated.
However, if the set of tests for specific vector register length have already been generated, the flag _-DBUILD_TEST_SOURCE=OFF_ can be added to prevent wasting time by re-generating the tests.

Support for co-simulation between Spike and the Verilator model is present.  In addition, there is also the option to enable a vector register commit log output from both Spike and Verilator to assist in debugging.  However, this feature is still in development.

A set of tests can be built and run according to the configuration in '_vector_config.cmake_' using the following commands once a verilator model has been built:

```
cd /build_tests
mkdir build
cd build
cmake ..
make
ctest
```

Note:  There is currently an issue when generating the ChipsAlliance suite for the first time.  Re-running the _cmake .._ command resolves the issue

