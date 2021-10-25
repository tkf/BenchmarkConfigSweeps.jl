# IO types that can be passed to `pipeline`
const NativeIO = Union{typeof(stdout),typeof(devnull),IOStream}  # whatelse?


function communicate(cmd; input, stdin::IO = IOBuffer(input), stdout::IO = IOBuffer(), stderr::IO = stderr)
    inio = Pipe()
    outio = stdout isa NativeIO ? Pipe() : stdout
    errio = stderr isa NativeIO ? Pipe() : stderr
    @sync begin
        proc = run(
            pipeline(cmd; stdin = inio, stdout = outio, stderr = errio);
            wait = false,
        )
        outio isa Pipe && close(outio.in)
        errio isa Pipe && close(errio.in)
        try
            stdout === outio || @async write(stdout, outio)
            stderr === errio || @async write(stderr, errio)
            try
                write(inio, stdin)
            finally
                close(inio)
            end
            wait(proc)
        catch
            stdout === outio || close(outio)
            stderr === errio || close(errio)
            close(inio)
            rethrow()
        end
    end
    return (; stdout = stdout, stderr = stderr)
end

# Use README as the docstring of the module:
function define_docstring()
    path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    doc = replace(read(path, String), r"^```julia"m => "```jldoctest README")
    @eval BenchmarkConfigSweeps $Base.@doc $doc BenchmarkConfigSweeps
end
