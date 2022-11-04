module ReplaceLibstdcxx

using JSON

export replace_libstdcxx, restore_libstdcxx, install_libstdcxx

function replace_libstdcxx(source_dir::String)
    if Sys.islinux() || Sys.isapple()
        julia_lib_dir = joinpath(dirname(Sys.BINDIR), "lib", "julia")
        julia_lib_file = get(filter(endswith(r"libstdc\+\+.so\.\d+\.\d+\.\d+"), readdir(julia_lib_dir, join = true)), 1, nothing)
        julia_lib_version = match(r"so(\.\d+)\.", julia_lib_file).captures[1]
        source_lib = get(filter(endswith(r"libstdc\+\+.so\.\d+\.\d+\.\d+"), readdir(source_dir, join = true)), 1, nothing)
        julia_lib = joinpath(dirname(Sys.BINDIR), "lib", "julia", "libstdc++.so")
        if julia_lib_file !== nothing && isfile(source_lib)
            for src in [julia_lib, julia_lib * julia_lib_version]
                islink(src) && rm(src, force = true)
                symlink(source_lib, src)
                @info read(`ls -al $src`, String)
            end
        end
    end
end

function replace_libstdcxx()
    libs = filter(x -> ! occursin("32", x), getindex.(split.(readlines(pipeline(`ldconfig -p`, `grep libstdc`)), r"\s*=>\s*"), 2))
    if length(libs) > 0
        if length(libs) > 1
            @info "More than one instance of libstdc++ found: \n" * join(libs, "\n") * "\n\nchosing: $(libs[end])"
        end
        replace_libstdcxx(dirname(libs[end]))
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
    elseif modulename == :Conda
        joinpath(dirname(m.BINDIR), "lib")
    end

    source_dir !== nothing && replace_libstdcxx(source_dir)
end

# restore original symlinks to libstdc++
function restore_libstdcxx()
    if Sys.islinux() || Sys.isapple()
        julia_lib_dir = joinpath(dirname(Sys.BINDIR), "lib", "julia")
        julia_lib_file = get(filter(startswith(r"libstdc\+\+.so\.\d+\.\d+\.\d+"), readdir(julia_lib_dir)), 1, nothing)
        
        if julia_lib_file !== nothing
            julia_lib_version = match(r"so(\.\d+)\.", julia_lib_file).captures[1]
            julia_lib = joinpath(julia_lib_dir, "libstdc++.so")
            for src in [julia_lib, julia_lib * julia_lib_version]
                islink(src) && rm(src, force = true)
                symlink(julia_lib_file, src)
                @info read(`ls -al $src`, String)
            end
        end
    end
end

function install_libstdcxx(m::Module)
    modulename = Base.nameof(m)
    source_dir = if modulename == :PythonCall
        arg = haskey(m.C.CondaPkg.current_packages(), "libstdcxx-ng") ? "update" : "install"
        run(m.C.CondaPkg.conda_cmd(`$arg -c conda-forge -y libstdcxx-ng`))
    elseif modulename == :PyCall
        if m.conda
            libs = getindex.(Conda.parseconda(`list`), "name")
            cmd = haskey(libs, "libstdcxx-ng") ? m.Conda.update : m.Conda.add
            cmd("libstdcxx-ng")
        else
            @info "PyCall is not configured to use conda. Looking for the system's package manager (micromamba, mamba, conda)"
            cmd = coalesce(replace(Sys.which.(["micromamba", "mamba", "conda"]), nothing => missing)...)
            if ismissing(cmd)
                @info "No package manager found, please call `install_libstdcxx(conda_cmd)`"
                return nothing
            end
            libs = getindex.(m.Conda.JSON.parse(read(`$cmd list --json`, String)), "name")
            arg = haskey(libs, "libstdcxx-ng") ? "update" : "install"
            run(`$cmd $arg -c conda-forge -y libstdcxx-ng`)
        end
    elseif modulename == :Conda
        libs = getindex.(m.parseconda(`list`), "name")
        cmd = haskey(libs, "libstdcxx-ng") ? m.update : m.add
        cmd("libstdcxx-ng")
    end
end

function install_libstdcxx(conda_cmd::AbstractString)
    libs = getindex.(JSON.parse(read(`$conda_cmd list --json`, String)), "name")
    arg = "libstdcxx-ng" in libs ? "update" : "install"
    run(`$conda_cmd $arg -c conda-forge -y libstdcxx-ng`)
end

end # module ReplaceLibstdcxx
