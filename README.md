# BenchmarkConfigSweeps

BenchmarkConfigSweeps.jl can be used for running benchmarks over various
`--nthreads` settings, environment variables, and `julia` versions.

Each configuration is specified as a combination of configuration specifiers
such as `BenchmarkConfigSweeps.nthreads`, `BenchmarkConfigSweeps.env`, and
`BenchmarkConfigSweeps.julia`.  The set of configurations to run benchmarks is
simply an iterable of (tuples of) such configuration specifiers:

```JULIA
using BenchmarkConfigSweeps

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
```

It can be then passed to `BenchmarkConfigSweeps.run`:

```JULIA
BenchmarkConfigSweeps.run("build", "benchmarks.jl", configs)
```

where `"build"` is the directory to store the result and `"benchmarks.jl"` is
the Julia script that defines the variable `SUITE :: BenchmarkGroup` at the
top-level.

The result can be loaded using

```JULIA
sweepresult = BenchmarkConfigSweeps.load("build")
```

The `sweepresult` object implements the Tables.jl interface. For example, it can
be easily converted into a `DataFrame` by

```JULIA
using DataFrames
df = DataFrame(sweepresult)
```

Note that the default table conversion is rather too DWIM-y in that it tries to
guess the meaning of `BenchmarkGroup` keys.  For more information, see
`BenchmarkConfigSweeps.flattable` for how it works.  Use
`BenchmarkConfigSweeps.simpletable` for programmatic processing.
