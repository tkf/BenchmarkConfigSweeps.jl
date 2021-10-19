using BenchmarkConfigSweeps
using DataFrames
using VegaLite

sweepresult = BenchmarkConfigSweeps.load(joinpath(@__DIR__, "build"))

df_raw = DataFrame(sweepresult)

begin
    df = select(df_raw, Not(:trial))
    df[:, :time_ns] = map(t -> minimum(t).time, df_raw.trial)
    rename!(df, :OPENBLAS_NUM_THREADS => :nthreads)
    df
end

df_speedup = combine(groupby(df, [:n])) do g
    t0 = only(g[g.nthreads.==1, :time_ns])
    (; g.nthreads, speedup = t0 ./ g.time_ns)
end

@vlplot(
    data = df_speedup,
    layer = [
        {
            mark = {:line, point = true},
            x = :nthreads,
            y = :speedup,
            color = {:n, type = :ordinal},
        },
        {mark = {type = :rule}, encoding = {y = {datum = 1}}},
    ]
)
