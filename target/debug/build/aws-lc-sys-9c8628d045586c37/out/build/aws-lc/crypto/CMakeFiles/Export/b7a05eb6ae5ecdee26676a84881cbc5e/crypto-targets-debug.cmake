#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "AWS::crypto" for configuration "Debug"
set_property(TARGET AWS::crypto APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(AWS::crypto PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "ASM_NASM;C"
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/aws_lc_0_34_0_crypto.lib"
  )

list(APPEND _cmake_import_check_targets AWS::crypto )
list(APPEND _cmake_import_check_files_for_AWS::crypto "${_IMPORT_PREFIX}/lib/aws_lc_0_34_0_crypto.lib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
