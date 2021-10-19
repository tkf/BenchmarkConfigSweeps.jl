"""
    BenchmarkConfigSweeps.run(resultdir, script, configs)
"""
function BenchmarkConfigSweeps.run(resultdir, script, configs)
    mkpath(resultdir)
    @argcheck isdir(resultdir) isfile(script)
    configs = vec(map(asconfig, configs))
    dumpinfo(infopath(resultdir), configs)
    sweep(resultdir, script, configs)
    return
end

# TODO: tune
# TODO: add a mode to run benchmarks in parallel using nthreads count
function sweep(resultdir, script, configs::Vector{Config})
    script = realpath(script)
    resultpathvar = "__BenchmarkConfigSweeps_resultpath"
    code = """
    include($(repr(script)))
    let results = run(SUITE; verbose = true),
        pkgid = Base.PkgId(Base.UUID(0x6e4b80f9dd6353aa95a30cdb28fa8baf), "BenchmarkTools"),
        BenchmarkTools = Base.require(pkgid)
        @info "Saving result to `\$$resultpathvar`"
        BenchmarkTools.save($resultpathvar, results)
    end
    """
    for (i, cfg) in enumerate(configs)
        path = resultpath(resultdir, i)
        cmd = Cmd(cfg)
        cmd = `$cmd -e "include_string(Main, read(stdin, String))"`
        @debug "$i-th benchmark: `$cmd`"
        open(pipeline(cmd; stdout = stdout, stderr = stderr); write = true) do io
            println(io, "$resultpathvar = $(repr(path))")
            println(io, code)
            close(io)
        end
    end
end
