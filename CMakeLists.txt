cmake_minimum_required(VERSION 3.15)

project(vcdwriter
    VERSION 1.0.0
    DESCRIPTION "Port of the PyVCD package from Python to C++"
    LANGUAGES CXX
)

# ------------------------------------------------------------------
# Are we the top-level project, or is someone add_subdirectory()-ing us?
# When used as a submodule the parent almost never wants our tester.
# ------------------------------------------------------------------
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(VCDWRITER_IS_TOP_LEVEL ON)
else()
    set(VCDWRITER_IS_TOP_LEVEL OFF)
endif()

option(VCDWRITER_BUILD_TESTER
       "Build test/vcd_writer_tester" ${VCDWRITER_IS_TOP_LEVEL})
option(VCDWRITER_WARNINGS_AS_ERRORS
       "Treat compiler warnings as errors" OFF)

# ------------------------------------------------------------------
# The library
#
# STATIC by default; configure with -DBUILD_SHARED_LIBS=ON for a .so.
# Static avoids having to deal with rpath / LD_LIBRARY_PATH downstream.
# ------------------------------------------------------------------
add_library(vcdwriter
    src/vcd_writer.cpp
    src/vcd_utils.cpp
)
add_library(vcdwriter::vcdwriter ALIAS vcdwriter)

# PUBLIC: anything linking vcdwriter gets include/ on its search path
# automatically, so the parent never hardcodes -I paths.
target_include_directories(vcdwriter PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# PUBLIC because vcd_writer.h itself needs C++11; consumers are bumped
# up to at least 11 but are free to compile at a newer standard.
target_compile_features(vcdwriter PUBLIC cxx_std_11)

# Keeps the objects linkable into a shared library downstream.
set_target_properties(vcdwriter PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    SOVERSION ${PROJECT_VERSION_MAJOR}
    VERSION   ${PROJECT_VERSION}
)

# PRIVATE: our warning settings are ours, not inflicted on the parent.
target_compile_options(vcdwriter PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall;-Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

if(VCDWRITER_WARNINGS_AS_ERRORS)
    target_compile_options(vcdwriter PRIVATE
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Werror>
        $<$<CXX_COMPILER_ID:MSVC>:/WX>
    )
endif()

# ------------------------------------------------------------------
# Tester
# ------------------------------------------------------------------
if(VCDWRITER_BUILD_TESTER)
    enable_testing()

    add_executable(vcd_writer_tester test/vcd_writer_tester.cpp)
    target_link_libraries(vcd_writer_tester PRIVATE vcdwriter)

    # The tester writes dump.vcd into its working directory.
    add_test(NAME vcd_writer_tester
             COMMAND vcd_writer_tester
             WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endif()
