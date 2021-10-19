abstract type AbstractConfig end

"""
    BenchmarkConfigSweeps.nthreads(n::Integer) -> config

Configuration for running the benchmark with `n` threads.
"""
BenchmarkConfigSweeps.nthreads

struct NThreadsConfig <: AbstractConfig
    value::Int
end

function BenchmarkConfigSweeps.nthreads(n::Integer)
    n = Int(n)
    if n ≤ 0
        error("`nthreads` must be positive: got $n")
    end
    return NThreadsConfig(n)
end

"""
    BenchmarkConfigSweeps.julia(cmd) -> config

Specify Julia runtime for running the benchmark.
"""
BenchmarkConfigSweeps.julia

@auto_hash_equals struct JuliaConfig <: AbstractConfig
    cmd::Vector{String}
end

# TODO: check that env, dir etc. are not set
BenchmarkConfigSweeps.julia(cmd::Cmd) = JuliaConfig(cmd.exec)
BenchmarkConfigSweeps.julia(cmd) = JuliaConfig(`$cmd`.exec)

"""
    BenchmarkConfigSweeps.env(pairs) -> config
    BenchmarkConfigSweeps.env(pairs::Pair...) -> config

Configuration for running the benchmark with given set of environment variables.
"""
BenchmarkConfigSweeps.env

@auto_hash_equals struct ENVConfig <: AbstractConfig
    dict::Dict{String,Any}
    inherit::Bool
end

function BenchmarkConfigSweeps.env(kvs; inherit::Bool = true)
    dict = Dict{String,Any}()
    for (k, v) in kvs
        if k isa Symbol
            k = String(k)
        else
            k = convert(String, k)
        end
        if !(v isa Union{AbstractString,Real})
            error("unsupported type of value $v for key $k")
        end
        dict[k] = v
    end
    return ENVConfig(dict, inherit)
end

BenchmarkConfigSweeps.env(kvs::Pair...; options...) =
    BenchmarkConfigSweeps.env(kvs; options...)

asenv(::Nothing) = nothing
function asenv(cfg::ENVConfig)
    if cfg.inherit
        env = copy(ENV)
    else
        env = Dict{String,String}()
    end
    for (k, v) in cfg.dict
        if v isa AbstractString
            env[k] = v
        else
            env[k] = string(v)
        end
    end
    return env
end

mergeenv(a, b) = ENVConfig(merge(a.dict, b.dict), a.inherit | b.inherit)
mergeenv(env, ::Nothing) = env
mergeenv(::Nothing, env) = env
mergeenv(::Nothing, ::Nothing) = nothing

@auto_hash_equals struct Config <: AbstractConfig
    julia::Union{Nothing,JuliaConfig}
    nthreads::Union{Nothing,NThreadsConfig}
    env::Union{Nothing,ENVConfig}
end

Config() = Config(nothing, nothing, nothing)
Config(julia::JuliaConfig) = Config(julia, nothing, nothing)
Config(nthreads::NThreadsConfig) = Config(nothing, nthreads, nothing)
Config(env::ENVConfig) = Config(nothing, nothing, env)

Base.merge(a::AbstractConfig, b::AbstractConfig) = merge(asconfig(a), asconfig(b))
function Base.merge(a::Config, b::Config)
    a = @set a.julia = something(b.julia, a.julia, Some(nothing))
    a = @set a.nthreads = something(b.nthreads, a.nthreads, Some(nothing))
    a = @set a.env = mergeenv(a.env, b.env)
    return a
end

asconfig(cfg::Config) = cfg
asconfig(cfg::AbstractConfig) = Config(cfg)
asconfig(configs::Tuple) = mapfoldl(asconfig, merge, configs; init = Config())

function Base.Cmd(cfg::Config)
    if cfg.julia === nothing
        cmd = Base.julia_cmd()
    else
        cmd = Cmd(cfg.julia.cmd)
    end
    if cfg.nthreads !== nothing
        cmd = `$cmd --threads=$(cfg.nthreads.value)`
    end
    env = asenv(cfg.env)
    if env !== nothing
        cmd = setenv(cmd, env)
    end
    return cmd
end

function Base.show(io::IO, cfg::NThreadsConfig)
    print(io, BenchmarkConfigSweeps, ".nthreads(", cfg.value, ")")
end

function Base.show(io::IO, cfg::JuliaConfig)
    print(io, BenchmarkConfigSweeps, ".julia(")
    show(io, cfg.cmd)
    print(io, ')')
end

function Base.show(io::IO, cfg::ENVConfig)
    print(io, BenchmarkConfigSweeps, ".env(")
    # TODO: don't print everything when `cfg.dict` is too large
    for (i, (k, v)) in enumerate(cfg.dict)
        i > 1 && print(io, ", ")
        show(io, k => v)
    end
    if cfg.inherit
        print(io, "; inherit = true")
    end
    print(io, ')')
end

StructTypes.StructType(::Type{<:AbstractConfig}) = StructTypes.Struct()
