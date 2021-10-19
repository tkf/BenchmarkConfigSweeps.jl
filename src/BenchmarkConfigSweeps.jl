baremodule BenchmarkConfigSweeps

# Config specifires
function env end
function nthreads end
function julia end

# Sweep execution
function run end

# Data loading
function load end
function simpletable end
function flattable end

module Internal

using ..BenchmarkConfigSweeps: BenchmarkConfigSweeps

import JSON3
import StructTypes
import Tables
using Accessors: @set
using ArgCheck: @argcheck
using AutoHashEquals: @auto_hash_equals
using BenchmarkTools: BenchmarkTools, BenchmarkGroup

include("utils.jl")
include("configurations.jl")
include("run.jl")
include("data.jl")

end  # module Internal

Internal.define_docstring()

end  # baremodule BenchmarkConfigSweeps
