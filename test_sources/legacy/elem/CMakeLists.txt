
###
# Add all Tests
###

include(${CMAKE_CURRENT_SOURCE_DIR}/../../../CMake/add_test.cmake)

file(GLOB files "*.S" )
foreach(item ${files})
    string(REPLACE ".S" "" test_name ${item})
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" test_name ${test_name})
    add_legacy_test(${test_name})
endforeach()

