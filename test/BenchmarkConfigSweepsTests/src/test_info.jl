module TestInfo

using BenchmarkConfigSweeps
using BenchmarkConfigSweeps.Internal: asconfig, asinfo, julia_info
using Test

function test_external_julia_info()
    julia = BenchmarkConfigSweeps.julia(Base.julia_cmd())
    @test julia_info(julia) == julia_info()
end

function test_asinfo()
    jl = Base.julia_cmd().exec[1]
    specs = [
        BenchmarkConfigSweeps.julia(`$jl --startup-file=no`),
        BenchmarkConfigSweeps.julia(`$jl --startup-file=no --check-bounds=yes`),
        BenchmarkConfigSweeps.julia(`$jl --startup-file=no`),
        BenchmarkConfigSweeps.julia(`$jl --startup-file=no --check-bounds=yes`),
    ]
    configs = asconfig.(specs)
    info = asinfo(configs)
    @test length(info.julia) == 2
end

end  # module
