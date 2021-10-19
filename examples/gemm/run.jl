using BenchmarkConfigSweeps

BenchmarkConfigSweeps.run(
    joinpath(@__DIR__, "build"),
    joinpath(@__DIR__, "benchmarks.jl"),
    BenchmarkConfigSweeps.env.(
        "OPENBLAS_NUM_THREADS" .=> 1:max(1, min(16, Sys.CPU_THREADS ÷ 2)),
    ),
)
