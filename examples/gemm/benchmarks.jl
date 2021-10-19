using BenchmarkTools
using LinearAlgebra

SUITE = BenchmarkGroup()
for n in [100, 400, 800]
    A = randn(n, n)
    B = randn(n, n)
    C = zero(A)
    SUITE["n=$n"] = @benchmarkable mul!($C, $A, $B)
end
