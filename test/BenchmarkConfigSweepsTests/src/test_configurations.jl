module TestConfigurations

using BenchmarkConfigSweeps
using BenchmarkConfigSweeps.Internal: asconfig
using Test

const BCS = BenchmarkConfigSweeps

function test_asconfig()
    @test asconfig(BCS.nthreads(2)).nthreads == BCS.nthreads(2)
    @test asconfig((BCS.nthreads(3), BCS.nthreads(2))).nthreads == BCS.nthreads(2)
    @test asconfig((BCS.env("A" => 0), BCS.nthreads(2))).nthreads == BCS.nthreads(2)
    @test asconfig((BCS.env("A" => 0), BCS.nthreads(2))).env == BCS.env("A" => 0)
    @test asconfig((BCS.env("A" => 0, "B" => false), BCS.env("A" => 1))).env ==
          BCS.env("A" => 1, "B" => false)
end

function test_readme()
    nthreads_list = [1, 4, 8, 16]
    configs = Iterators.product(
        zip(
            BenchmarkConfigSweeps.nthreads.(nthreads_list),
            BenchmarkConfigSweeps.env.("OPENBLAS_NUM_THREADS" .=> nthreads_list),
        ),
        BenchmarkConfigSweeps.env.(
            "JULIA_PROJECT" .=> ["baseline", "target"],
            "JULIA_LOAD_PATH" => "@",  # not varied
        ),
        BenchmarkConfigSweeps.julia.(["julia1.5", "julia1.6"]),
    )

    configs = map(asconfig, configs)
    @test length(configs) == 4 * 2 * 2
    @test configs[1].nthreads == BCS.nthreads(1)
    @test configs[1].env == BCS.env(
        "OPENBLAS_NUM_THREADS" => 1,
        "JULIA_PROJECT" => "baseline",
        "JULIA_LOAD_PATH" => "@",
    )
    @test configs[1].julia == BCS.julia("julia1.5")
end

end  # module
