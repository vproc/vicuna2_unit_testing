
####
#Add bsp library for Vicuna
####
add_library(bsp_Vicuna STATIC)

target_include_directories(bsp_Vicuna PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
)

target_sources(bsp_Vicuna PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/crt0.S
)

