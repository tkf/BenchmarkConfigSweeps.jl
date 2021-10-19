function asinfo(configs::Vector{Config})
    return (
        BenchmarkConfigSweeps = (
            version = "0.1.0",  # TODO: load it from Project.toml
        ),
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

infopath(resultdir) = joinpath(resultdir, "info.json")
resultpath(resultdir, i::Integer) = joinpath(resultdir, "result-$i.json")

function loadresults(resultdir, n::Integer)
    results = Vector{Union{BenchmarkGroup,Nothing}}(undef, n)
    fill!(results, nothing)
    for i in 1:n
        path = resultpath(resultdir, i)
        data = BenchmarkTools.load(path)
        @assert length(data) == 1
        results[i], = data
    end
    return results
end

"""
    BenchmarkConfigSweeps.load(resultdir) -> sweepresult

Load `sweepresult` from `resultdir`.

`sweepresult` object satisfies the row table interface.
`Tables.rows(sweepresult)` is an alias of
`BenchmarkConfigSweeps.flattable(sweepresult)`. For example,
`DataFrame(sweepresult)` can be used to obtain the sweeps as a flat table.

Note that `BenchmarkConfigSweeps.flattable` aggressively flatten/splat
environment variables and tries to interpret benchmark group keys.  For
programatic processing, use [`BenchmarkConfigSweeps.simpletable`](@ref) which
produces a predictable output.
"""
function BenchmarkConfigSweeps.load(resultdir)
    info = loadinfo(infopath(resultdir))
    results = loadresults(resultdir, length(info.configs))
    return SweepResult(resultdir, info, results)
end

struct SweepResult
    resultdir::String
    info::Info
    results::Vector{Union{BenchmarkGroup,Nothing}}
end

function Base.show(io::IO, result::SweepResult)
    print(io, BenchmarkConfigSweeps, ".load(")
    show(io, result.resultdir)
    print(io, ')')
end

function _simpletable(result::SweepResult)
    results = result.results
    configs = result.info.configs::Vector{Config}
    return (
        julia = Union{Missing,Vector{String}}[
            cfg.julia === nothing ? missing : cfg.julia.cmd for cfg in configs
        ],
        nthreads = Union{Missing,Int}[
            cfg.nthreads === nothing ? missing : cfg.nthreads.value for cfg in configs
        ],
        env = Union{Missing,Dict{String,Any}}[
            cfg.env === nothing ? missing : cfg.env.dict for cfg in configs
        ],
        env_inherit = Union{Missing,Bool}[
            cfg.env === nothing ? missing : cfg.env.inherit for cfg in configs
        ],
        result = Union{Missing,BenchmarkGroup}[
            g === nothing ? missing : g for g in results
        ],
    )
end

function try_parse_kv(str)
    i = findfirst('=', str)
    i === nothing && return nothing
    k = Symbol(strip(SubString(str, 1:i-1)))

    j = findfirst(!isspace, SubString(str, i+1:lastindex(str)))
    j === nothing && return nothing
    vstr = SubString(str, i+j:lastindex(str))

    v = tryparse(Int64, vstr)
    if v !== nothing
        return k => v
    end

    v = tryparse(Float64, vstr)
    if v !== nothing
        return k => v
    end

    if startswith(vstr, ':') && lastindex(vstr) > 1
        return k => Symbol(SubString(vstr, firstindex(vstr)+1:lastindex(vstr)))
    end

    return k => vstr
end

dont_parsekeys(ks) = (; trialkeys = ks)

function dwim_parsekeys(strings)
    vals = Pair{Symbol,Any}[]
    for (i, str) in enumerate(strings)
        kv = try_parse_kv(str)
        if kv === nothing
            push!(vals, Symbol(:level_, i) => str)
        else
            push!(vals, kv)
        end
    end
    return vals
end

# TODO: type-stabilize by using "concrete" dynamic dispatch
function BenchmarkConfigSweeps.flattable(result::SweepResult; parsekeys = dwim_parsekeys)
    parsekeys = something(parsekeys, dont_parsekeys)

    simple = _simpletable(result)
    cols = Pair{Symbol,Vector}[]
    if !all(ismissing, simple.julia)
        push!(cols, :julia => simple.julia)
    end
    if !all(ismissing, simple.nthreads)
        push!(cols, :nthreads => simple.nthreads)
    end

    envkeys = mapfoldl(union!, simple.env; init = Set{String}()) do env
        env === missing ? () : keys(env)
    end
    if !isempty(envkeys)
        for k in sort!(collect(envkeys))
            vs = map(simple.env) do env
                env === missing && return missing
                get(env, k, missing)
            end
            push!(cols, Symbol(k) => vs)
        end
    end

    configrows = Tables.rows(Tables.CopiedColumns((; cols...)))
    # TODO: check duplicates

    rows = let parsekeys = parsekeys
        Iterators.map(zip(simple.result, configrows)) do (result, config)
            Iterators.map(BenchmarkTools.leaves(result)) do (ks, trial)
                (; NamedTuple(config)..., parsekeys(ks)..., trial = trial)
            end
        end |>
        Iterators.flatten |>
        collect
    end

    return rows
end

BenchmarkConfigSweeps.simpletable(result::SweepResult) =
    Tables.CopiedColumns(_simpletable(result))

Tables.istable(::Type{SweepResult}) = true
Tables.rowaccess(::Type{SweepResult}) = true
Tables.rows(result::SweepResult) = BenchmarkConfigSweeps.flattable(result)
