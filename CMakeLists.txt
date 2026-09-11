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

option(VCDWRITER_BUILD_STATIC "Build the static library" ON)
option(VCDWRITER_BUILD_SHARED "Build the shared library" ON)
option(VCDWRITER_BUILD_TESTER
       "Build test/vcd_writer_tester" ${VCDWRITER_IS_TOP_LEVEL})
option(VCDWRITER_WARNINGS_AS_ERRORS
       "Treat compiler warnings as errors" OFF)

if(NOT VCDWRITER_BUILD_STATIC AND NOT VCDWRITER_BUILD_SHARED)
    message(FATAL_ERROR
        "Both VCDWRITER_BUILD_STATIC and VCDWRITER_BUILD_SHARED are OFF; "
        "there would be nothing to build.")
endif()

set(VCDWRITER_SOURCES
    src/vcd_writer.cpp
    src/vcd_utils.cpp
)

# ------------------------------------------------------------------
# The libraries
#
# Both flavours are built by default and share one output name, so the
# results are libvcdwriter.a and libvcdwriter.so.1.0.0 side by side.
# ------------------------------------------------------------------
set(VCDWRITER_TARGETS "")

if(VCDWRITER_BUILD_STATIC)
    add_library(vcdwriter_static STATIC ${VCDWRITER_SOURCES})
    add_library(vcdwriter::vcdwriter_static ALIAS vcdwriter_static)
    list(APPEND VCDWRITER_TARGETS vcdwriter_static)
endif()

if(VCDWRITER_BUILD_SHARED)
    add_library(vcdwriter_shared SHARED ${VCDWRITER_SOURCES})
    add_library(vcdwriter::vcdwriter_shared ALIAS vcdwriter_shared)
    set_target_properties(vcdwriter_shared PROPERTIES
        SOVERSION ${PROJECT_VERSION_MAJOR}
        VERSION   ${PROJECT_VERSION}
    )
    list(APPEND VCDWRITER_TARGETS vcdwriter_shared)
endif()

foreach(vcdwriter_target IN LISTS VCDWRITER_TARGETS)
    set_target_properties(${vcdwriter_target} PROPERTIES
        OUTPUT_NAME vcdwriter
        POSITION_INDEPENDENT_CODE ON
    )

    # PUBLIC: anything linking us gets include/ on its search path
    # automatically, so the parent never hardcodes -I paths.
    target_include_directories(${vcdwriter_target} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    )

    # PUBLIC because vcd_writer.h itself needs C++11. This is a minimum,
    # not a pin: consumers are free to compile at a newer standard.
    target_compile_features(${vcdwriter_target} PUBLIC cxx_std_11)

    # PRIVATE: our warning settings are ours, not inflicted on the parent.
    target_compile_options(${vcdwriter_target} PRIVATE
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall;-Wextra>
        $<$<CXX_COMPILER_ID:MSVC>:/W4>
    )

    if(VCDWRITER_WARNINGS_AS_ERRORS)
        target_compile_options(${vcdwriter_target} PRIVATE
            $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Werror>
            $<$<CXX_COMPILER_ID:MSVC>:/WX>
        )
    endif()
endforeach()

# Default target for consumers that do not care which flavour they get.
# Static is preferred: it needs no rpath handling downstream.
if(VCDWRITER_BUILD_STATIC)
    add_library(vcdwriter::vcdwriter ALIAS vcdwriter_static)
else()
    add_library(vcdwriter::vcdwriter ALIAS vcdwriter_shared)
endif()

# ------------------------------------------------------------------
# Tester
# ------------------------------------------------------------------
if(VCDWRITER_BUILD_TESTER)
    enable_testing()

    add_executable(vcd_writer_tester test/vcd_writer_tester.cpp)
    target_link_libraries(vcd_writer_tester PRIVATE vcdwriter::vcdwriter)

    # The tester writes dump.vcd into its working directory.
    add_test(NAME vcd_writer_tester
             COMMAND vcd_writer_tester
             WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endif()
