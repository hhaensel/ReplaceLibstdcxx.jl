module ReplaceLibstdcxx

export replace_libstdcxx, restore_libstdcxx

function replace_libstdcxx(source_dir::String)
    if Snys.islinux() || Sys.isapple()
        try
            julia_lib_dir = joinpath(dirname(Sys.BINDIR), "lib", "julia")
            julia_lib_file = get(filter(endswith(r"libstdc\+\+.so\.\d+\.\d+\.\d+"), readdir(julia_lib_dir, join = true)), 1, nothing)
            julia_lib_version = match(r"so(\.\d+)\.", julia_lib_file).captures[1]
            source_lib = get(filter(endswith(r"libstdc\+\+.so\.\d+\.\d+\.\d+"), readdir(source_dir, join = true)), 1, nothing)
            julia_lib = joinpath(dirname(Sys.BINDIR), "lib", "julia", "libstdc++.so")
            if julia_lib_file !== nothing && isfile(source_lib)
                for src in [julia_lib, julia_lib * julia_lib_version]
                    isfile(src) && rm(src)
                    symlink(source_lib, src)
                end
            end
        catch _
        end
    end
end

function replace_libstdcxx(m::Module;
        venv::Union{Nothing, AbstractString} = nothing,
        python::AbstractString = "")

    modulename = Base.nameof(m)
    source_dir = if modulename == :PythonCall
        dirname(m.C.CTX.lib_path)
    elseif modulename == :PyCall
        dirname(m.find_libpython(m.python_cmd(; venv, python = python == "" ? m.venv_python(venv) : python)[1]))
    end
    source_dir !== nothing && replace_libstdcxx(source_dir)
end

# restore original symlinks to libstdc++
function restore_libstdcxx()
    if Sys.islinux() || Sys.isapple()
        try
            julia_lib_dir = joinpath(dirname(Sys.BINDIR), "lib", "julia")
            julia_lib_file = get(filter(startswith(r"libstdc\+\+.so\.\d+\.\d+\.\d+"), readdir(julia_lib_dir)), 1, nothing)
            if julia_lib_file !== nothing
                julia_lib_version = match(r"so(\.\d+)\.", julia_lib_file).captures[1]
                julia_lib = joinpath(julia_lib_dir, "libstdc++.so")
                for src in [julia_lib, julia_lib * julia_lib_version]
                    isfile(src) && rm(src)
                    symlink(julia_lib_file, src)
                end
            end
        catch _
        end
    end
end

end # module ReplaceLibstdcxx
