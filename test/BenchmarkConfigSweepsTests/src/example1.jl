using BenchmarkTools

SUITE = BenchmarkGroup()
BCST_A = parse(Int, ENV["BCST_A"])
for i in [0, 1]
    k1 = i * BCST_A
    SUITE["k1=$k1"] = @benchmarkable nothing
end
