
###
# Add all folders based on chosen architecture
###

add_subdirectory(bsp)

set(LEGACY_DIR ${CMAKE_CURRENT_SOURCE_DIR})

if (RISCV_F)
  add_subdirectory(f)
endif()

if (RISCV_ZFH)
  add_subdirectory(zfh)
endif()

if (RISCV_ZVE32X)
  add_subdirectory(alu)
  add_subdirectory(csr)
  #add_subdirectory(div)
  add_subdirectory(elem)
  add_subdirectory(kernel)
  add_subdirectory(lsu)
  add_subdirectory(misc)
  add_subdirectory(mul)
  add_subdirectory(sld)
endif()

if (RISCV_ZVE32F)
  add_subdirectory(zve32f)
endif()

if (RISCV_ZVFH)
  add_subdirectory(zvfh)
endif()

