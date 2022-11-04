# ReplaceLibstdcxx

Package to simplify the replacement of Julia's `libstdc++.so`.


## Installation

```julia
using Pkg
Pkg.add("ReplaceLibstdcxx")
```
or
```julia
]add ReplaceLibstdcxx
```


## Background

The replacement of Julia's `libstdc++.so` may sometimes be necessary, when Julia accesses precompiled libraries that require a higher version of `libstdc++.so`.
One example is the usage of the Python package `pyarrow` via PyCall or PythonCall, which fails with the `libstdc++.so` that Julia was compiled with.
A typical error for a version mismatch is
```julia-repl
julia> pyimport("pyarrow")

ERROR: Python: ImportError: /opt/julia-1.8.2/bin/../lib/julia/libstdc++.so.6: version `GLIBCXX_3.4.30' not found (required by /home/user123/.julia/conda/3/lib/python3.10/site-packages/pyarrow/../../../libarrow.so.900)
```

This package provides

- `install_libstdcxx()` for installing the required `libstdc++.so`
- `replace_libstdcxx()` for symlinking the correct libraries
- `restore_libstdcxx()` for resetting the original state
- 
## Usage

### - Symlinking to the system's libraries.
If you have an up-to-date system it is highly probable that the system's  `libstdc++.so` has the latest version.
 ```julia
using ReplaceLibstdcxx

replace_libstdcxx()
```
### - Installing the library via PythonCall or PyCall or Conda and symlinking them

```julia
using PythonCall
using ReplaceLibstdcxx

install_libstdcxx(PythonCall)
replace_libstdcxx(PythonCall)
```
You can chose any of the three modules as argument.

### - Installing via providing the path to a `conda`, `mamba` or `micromamba` executable and symlinking via provding the lib dir containing the installed libraries.

```julia
using ReplaceLibstdcxx

install_libstdcxx(path_to_conda)
replace_libstdcxx(path_to_libdir_containing_libstdc++.so)
```
After replacing the library links you have to exit Julia and restart to have Julia use the new library.

Finally, all changes can be reset by
```julia
restore_libstdcxx()
```
Note that on some systems you may have to grant admistrator access rights to make the required changes. on Ubuntu you would start Julia with `sudo julia`.
In that case, it might be a good idea to install the libraries as a normal user and to do the replacement via providing the lib dir as admin.
