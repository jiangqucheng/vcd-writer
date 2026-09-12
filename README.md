# vcd-writer

Port PyVCD package from python to C++

Visit [PyVCD on GitHub](https://github.com/SanDisk-Open-Source/pyvcd/).

It writes Value Change Dump (VCD) files as specified in IEEE 1364-2005.

Building
--------

Both build systems produce the same two libraries under the same names,
`libvcdwriter.a` and `libvcdwriter.so` (`.dylib` on macOS). They write to
different directories, so they never collide.

### CMake (recommended)

```sh
cmake -B build
cmake --build build
```

This produces, in `build/`:

```
libvcdwriter.a
libvcdwriter.so -> libvcdwriter.so.1 -> libvcdwriter.so.1.0.0
vcd_writer_tester            # stand-alone builds only
```

Run the tester through CTest:

```sh
cd build && ctest --output-on-failure
```

Configure-time options:

| Option | Default | Effect |
| --- | --- | --- |
| `VCDWRITER_BUILD_STATIC` | `ON` | Build `libvcdwriter.a` |
| `VCDWRITER_BUILD_SHARED` | `ON` | Build the versioned `libvcdwriter.so` |
| `VCDWRITER_BUILD_TESTER` | `ON` stand-alone, `OFF` as a subproject | Build `vcd_writer_tester` |
| `VCDWRITER_WARNINGS_AS_ERRORS` | `OFF` | Add `-Werror` (`/WX` on MSVC) |

Turning both library options off is an error. For example, to build only
the static library with warnings fatal:

```sh
cmake -B build -DVCDWRITER_BUILD_SHARED=OFF -DVCDWRITER_WARNINGS_AS_ERRORS=ON
cmake --build build
```

### Make

```sh
make          # static + shared + tester
make static   # lib/libvcdwriter.a only
make shared   # lib/libvcdwriter.so* only
make test     # build and run the tester
make clean
```

Output lands in `lib/`, with object files in `obj/`. The variables mirror
the CMake options:

| Variable | Default | Effect |
| --- | --- | --- |
| `WARNINGS_AS_ERRORS` | `0` | `1` adds `-Werror` |
| `CXXSTD` | empty | Compile at a specific standard, e.g. `make CXXSTD=c++11` |

Requirements: a C++11 compiler. CMake 3.15 or newer for the CMake path.
There are no external dependencies.

Neither build system pins the language standard by default; C++11 is a
floor, not a target, so the library is compiled the same way as whatever
consumes it.

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

Three targets are exported:

| Target | Resolves to |
| --- | --- |
| `vcdwriter::vcdwriter` | The static library, or the shared one if static is disabled |
| `vcdwriter::vcdwriter_static` | Always the static library |
| `vcdwriter::vcdwriter_shared` | Always the shared library |

Prefer `vcdwriter::vcdwriter` unless you specifically need one flavour.
The static default means your executable has no run-time library lookup
to arrange.

### CMake, via FetchContent

```cmake
include(FetchContent)
FetchContent_Declare(vcdwriter
    GIT_REPOSITORY https://github.com/jiangqucheng/vcd-writer.git
    GIT_TAG        master
)
FetchContent_MakeAvailable(vcdwriter)

target_link_libraries(myapp PRIVATE vcdwriter::vcdwriter)
```

### Without CMake

Against the static library:

```sh
g++ -I vcd/include -o myapp myapp.cpp vcd/lib/libvcdwriter.a
```

Against the shared library:

```sh
g++ -I vcd/include -o myapp myapp.cpp \
    -L vcd/lib -lvcdwriter -Wl,-rpath,'$ORIGIN/vcd/lib'
```

The `-rpath` is what lets the binary find the `.so` at run time. Without
it you have to set `LD_LIBRARY_PATH=vcd/lib` on every run. Linking the
static library sidesteps the issue entirely.

Substitute `vcd/build` for `vcd/lib` if you built with CMake.

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
