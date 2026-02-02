# Vicuna2_unit_testing
Unit Testing Framework for Vicuna.  Includes legacy handwritten unit tests, as well as the ChipsAlliance Tests for the V extension

# Getting Started

The repository is composed of two CMake projects.

The first is under '*/build_model*'.  This project builds the verilator model to test.  This folder contains the top level _CMakelist.txt_ file.  It also contains the '*vector_config.cmake*' file, which should be used to change configurations of the vector unit.  

Currently two scalar cores are supported:
<ul>
  <li>[CV32E40X](https://github.com/openhwgroup/cv32e40x)</li>
  <li>[CV32A60X](https://github.com/openhwgroup/cva6/tree/cv32a60x)</li>
</ul> 


As the interfaces for each core is different, a folder containing the core specific integration *vproc_top.sv* and *verilator_main.cpp* are present in the */build_model* folder.  Additionally, some core specific simulation functions have been added, and are included in the built model.


The Verilator model CMake project uses the rtl sources in the */rtl* folder, which are all added as submodules.  Note that the versions of the scalar cores used in this repository are development forks, as some bug fixes which have been found have not yet been upstreamed.


A model can be built according to the configuration in '*vector_config.cmake*' using the following commands:

```
git submodule update --init --recursive
cd /build_model
mkdir build
cd build
cmake ..
make
```

The second CMake project is located in the '*/build_tests*' folder.  All test sources are located in the '_/test_sources_' folder.  The tests are added to the CTest framework.


Two types of unit tests are currently supported in this repository.
<ul>
  <li> Legacy Tests - these are the original handwritten unit tests used for Vicuna1.0, along with additional tests written in this style for floating point operations</li>
  <li> ChipsAlliance Vector Tests - these are generated using the generator from ChipsAlliance under the [riscv-vector-tests](https://github.com/chipsalliance/riscv-vector-tests) repository</li>
</ul> 


The type of test compiled and run can be changed with the flag *-DLegacy=ON*.  The default is to run the ChipsAlliance tests.

The ChipsAlliance test generator depends on the vector register length.  This parameter is imported from the '*vector_config.cmake*' file.  If it is changed, a new set of tests AND verilator model must be generated.
However, if the set of tests for specific vector register length have already been generated, the flag *-DBUILD_TEST_SOURCE=OFF* can be added to prevent wasting time by re-generating the tests.


The output of VCD traces can be enabled using the *-DTRACE=ON* flag.  This flag must be added to both the Verilator model and test programs.
Support for co-simulation between Spike and the Verilator model is present.  In addition, there is also the option to enable a vector register commit log output from both Spike and Verilator to assist in debugging.  However, this feature is still in development.


A set of tests can be built and run according to the configuration in '*vector_config.cmake*' using the following commands once a verilator model has been built:

```
cd /build_tests
mkdir build
cd build
cmake ..
make
ctest
```

Note:  There is currently an issue when generating the ChipsAlliance suite for the first time.  Re-running the _cmake .._ command resolves the issue

