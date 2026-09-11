# vcd-writer

Port PyVCD package from python to C++

Visit [PyVCD on GitHub](https://github.com/SanDisk-Open-Source/pyvcd/).

It writes Value Change Dump (VCD) files as specified in IEEE 1364-2005.

Building
--------

### CMake (recommended)

```sh
cmake -B build
cmake --build build
```

This produces `build/libvcdwriter.a` and, when built stand-alone, the
`build/vcd_writer_tester` demo. Run it through CTest:

```sh
cd build && ctest --output-on-failure
```

Configure-time options:

| Option | Default | Effect |
| --- | --- | --- |
| `BUILD_SHARED_LIBS` | `OFF` | `ON` builds `libvcdwriter.so` instead of the static library |
| `VCDWRITER_BUILD_TESTER` | `ON` stand-alone, `OFF` as a subproject | Builds `test/vcd_writer_tester` |
| `VCDWRITER_WARNINGS_AS_ERRORS` | `OFF` | Adds `-Werror` (`/WX` on MSVC) |

For example, a shared build with warnings fatal:

```sh
cmake -B build -DBUILD_SHARED_LIBS=ON -DVCDWRITER_WARNINGS_AS_ERRORS=ON
cmake --build build
```

### Make

```sh
make          # builds lib/libvcd_writer.so and test/vcd_writer_tester
make clean
```

Note the Makefile produces a **shared** library named `libvcd_writer.so`
(with an underscore), while CMake produces `libvcdwriter` (without one).
The two build systems are independent; pick whichever you prefer.

Requirements: a C++11 compiler. CMake 3.15 or newer for the CMake path.
There are no external dependencies.

Using the library
-----------------

### CMake, as a git submodule

```sh
git submodule add https://github.com/jiangqucheng/vcd-writer vcd
```

```cmake
add_subdirectory(vcd)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE vcdwriter::vcdwriter)
```

That is all that is needed. The include path and the C++11 requirement
travel with the target, so `#include "vcd_writer.h"` works with no
`include_directories()` call on your side, and the tester is not built.

### CMake, via FetchContent

```cmake
include(FetchContent)
FetchContent_Declare(vcdwriter
    GIT_REPOSITORY https://github.com/jiangqucheng/vcd-writer.git
    GIT_TAG        main
)
FetchContent_MakeAvailable(vcdwriter)

target_link_libraries(myapp PRIVATE vcdwriter::vcdwriter)
```

### Without CMake

Against the static library from the CMake build:

```sh
g++ -std=c++11 -I vcd/include -o myapp myapp.cpp vcd/build/libvcdwriter.a
```

Against the shared library from the Makefile build:

```sh
g++ -std=c++11 -I vcd/include -o myapp myapp.cpp \
    -L vcd/lib -lvcd_writer -Wl,-rpath,'$ORIGIN/vcd/lib'
```

The `-rpath` is what lets the binary find the `.so` at run time. Without
it you have to set `LD_LIBRARY_PATH=vcd/lib` on every run. Linking the
static library sidesteps the issue entirely.

Quick Start
-----------
```C++
#include "vcd_writer.h"
using namespace vcd;
	
HeadPtr head = makeVCDHeader(TimeScale::ONE, TimeScaleUnit::ns, utils::now());
std::string filename = "dump.vcd";
VCDWriter writer(filename, head);
VarPtr counter_var = writer.register_var("a.b.c", "counter", VariableType::integer, 8);
VarPtr var_var = writer.register_var("a.b", "var", VariableType::integer, 8);
for (int timestamp = 0; timestamp < 5; ++timestamp)
{
	const int c_val = 10 + timestamp * 2;
	const int v_val = 11 + timestamp * 2;
	writer.change(counter_var, timestamp, std::bitset<8>(c_val).to_string());
	writer.change(var_var, timestamp, std::bitset<8>(v_val).to_string());
}
```

Output:
```vcd
$timescale 1 ns $end
$date 2022-04-18 11:12:38 $end
$scope module a $end
$scope module b $end
$var integer 8 1 var $end
$upscope $end
$scope module b $end
$scope module c $end
$var integer 8 0 counter $end
$upscope $end
$upscope $end
$upscope $end
$enddefinitions $end
#0
$dumpvars
b00001010 0
b00001011 1
$end
#1
b00001100 0
b00001101 1
#2
b00001110 0
b00001111 1
#3
b00010000 0
b00010001 1
#4
b00010010 0
b00010011 1
```
