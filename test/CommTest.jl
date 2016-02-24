module CommTest

using Comm
using Base.Test



function remote1(i, s, a)
    @test myproc() == (nprocs() < 2 ? 1 : 2)
    @test i == 1
    @test s == "a"
    @test a == [1.0]
    rexec(remote2, nprocs())
end

function remote2()
    @test myproc() == nprocs()
    rexec(1) do
        remote3()
    end
end

function remote3()
    @test myproc() == 1
    global DONE = true
end

function inc()
    # rexec(() -> global COUNTER += 1, 1)
    rexec(inc1, 1)
end
function inc1()
    global COUNTER += 1
end



# local function
let
    @test myproc() == 1
    global DONE = false
    rexec(mod1(2, nprocs())) do
        remote1(1, "a", [1.0])
    end
    while !DONE yield() end
end

let
    @test myproc() == 1
    global DONE = false
    i=1
    rexec(()->(s="a"; remote1(i, s, [1.0])), mod1(2, nprocs()))
    while !DONE yield() end
end

let
    @test myproc() == 1
    global DONE = false
    i=1
    s="a"
    f() = remote1(i, s, [1.0])
    rexec(f, mod1(2, nprocs()))
    while !DONE yield() end
end

let
    global COUNTER = 0
    rexec_everywhere(inc)
    while COUNTER < nprocs() yield() end
end

# local macro
let
    while !DONE yield() end
    global DONE = false
    @rexec mod1(2, nprocs()) remote1(1, "a", [1.0])
    while COUNTER < nprocs() yield() end
end

let
    while !DONE yield() end
    global DONE = false
    i=1
    @rexec mod1(2, nprocs()) (s="a"; remote1(i, s, [1.0]))
    while COUNTER < nprocs() yield() end
end

let
    global COUNTER = 0
    @rexec_everywhere inc()
    while COUNTER < nprocs() yield() end
end

end
