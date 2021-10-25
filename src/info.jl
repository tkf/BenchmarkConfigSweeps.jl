function julia_info()
    return (
        version = string(VERSION),
        git = (
            commit = Base.GIT_VERSION_INFO.commit,
            branch = Base.GIT_VERSION_INFO.branch,
        ),
        is_debugbuild = ccall(:jl_is_debugbuild, Cint, ()) != 0,
        libllvm_version = Base.libllvm_version,
        Sys = (
            WORD_SIZE = Sys.WORD_SIZE,
            JIT = Sys.JIT,
            # CPU_NAME = Sys.CPU_NAME,
            # CPU_THREADS = Sys.CPU_THREADS,
        ),
    )
end

const JuliaInfo = typeof(julia_info())
const JuliaInfoWithCommand = typeof((; command = String[], julia_info()...))

function julia_info(julia::JuliaConfig)
    # TODO: Don't assume project-compatibility
    code = """
    $(Base.load_path_setup_code())

    using BenchmarkConfigSweeps
    using BenchmarkConfigSweeps.Internal: JSON3, julia_info
    JSON3.write(stdout, julia_info())
    """

    cmd = Cmd(julia.cmd)
    cmd = `$cmd --startup-file=no -e 'include_string(Main, read(stdin, String))'`
    outio = communicate(cmd; input = code).stdout
    output = String(take!(outio))
    return JSON3.read(output, JuliaInfo)
end

function asinfo(configs::Vector{Config})
    julia_configs =
        unique!(JuliaConfig[cfg.julia for cfg in configs if cfg.julia !== nothing])
    if isempty(julia_configs)
        julia = [(; command = String[], julia_info()...)]
    else
        julia = [(; command = jl.cmd, julia_info(jl)...) for jl in julia_configs]
    end
    return (
        BenchmarkConfigSweeps = (
            version = "0.0.1",  # TODO: load it from Project.toml
        ),
        julia = julia::Vector{JuliaInfoWithCommand},
        configs = configs,
        # TODO: add more metadata? begin/end time?
    )
end

const Info = typeof(asinfo(Config[]))

function dumpinfo(path, configs::Vector{Config})
    info = asinfo(configs)
    JSON3.write(path, info)
end

loadinfo(path) = JSON3.read(read(path, String), Info)
