module TestExamples

using BenchmarkConfigSweeps
using Tables
using Test

function test_example1()
    configs = Iterators.product(
        BenchmarkConfigSweeps.nthreads.(1:2),
        BenchmarkConfigSweeps.env.(
            "BCST_A" .=> [33, 44],  # read in ./example1.jl
            "BCST_B" => "not varied",
        ),
    )
    mktempdir() do resultdir
        BenchmarkConfigSweeps.run(resultdir, joinpath(@__DIR__, "example1.jl"), configs)

        sweepresult = BenchmarkConfigSweeps.load(resultdir)

        st = BenchmarkConfigSweeps.simpletable(sweepresult)
        @test length(st.env) == 4

        ft = Tables.columns(sweepresult)
        @test ft.nthreads == [1, 1, 2, 2, 1, 1, 2, 2]
        @test ft.BCST_A == [33, 33, 33, 33, 44, 44, 44, 44]
        @test ft.k1 == [0, 33, 0, 33, 0, 44, 0, 44]
    end
end

end  # module
