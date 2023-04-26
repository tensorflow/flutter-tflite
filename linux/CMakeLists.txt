cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "tflite_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "tflite_flutter_plugin")

add_library(${PLUGIN_NAME} SHARED
  "tflite_flutter_plugin.cc"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

include(ExternalProject)
ExternalProject_add(tensorflowlite_c
  GIT_REPOSITORY  "https://github.com/tensorflow/tensorflow.git"
  SOURCE_SUBDIR   "tensorflow/lite/c"
  CMAKE_ARGS      -DTFLITE_ENABLE_GPU=ON
  )
add_dependencies(${PLUGIN_NAME} tensorflowlite_c)
ExternalProject_Get_Property(tensorflowlite_c binary_dir)
# List of absolute paths to libraries that should be bundled with the plugin
set(tflite_flutter_bundled_libraries
  "${binary_dir}/libtensorflowlite_c.so"
  PARENT_SCOPE
)
