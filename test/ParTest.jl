module ParTest

using Comm, Foldable, Functor, FunRefs, Funs, Monad, Par
using Base.Test
using Combinatorics



function inc(i::Integer)
    i+1
end



function local_fun_untyped()
    # par
    r1 = par() do
        inc(1)
    end
    @test isa(r1, FunRef{Any})
    @test islocal(r1)
    @test r1[] == 2

    # rpar
    r3 = rpar(mod1(2, Comm.nprocs())) do
        inc(3)
    end
    @test isa(r3, FunRef{Any})
    @test islocal(r3)
    @test r3[] == 4

    # rcall
    v4 = rcall(mod1(2, Comm.nprocs())) do
        inc(4)
    end
    @test v4 == 5

    # remote
    r6 = remote(mod1(2, Comm.nprocs())) do
        inc(6)
    end
    @test isa(r6, FunRef{Any})
    @test (Comm.nprocs()==1) == islocal(r6)

    # get
    v6 = rcall(getproc(r6)) do
        r6[]
    end
    @test v6 == 7

    # make_local
    r7 = make_local(r6)
    @test isa(r7, FunRef{Any})
    @test islocal(r7)
    @test r7[] == 7

    # get_local
    v7 = get_local(r7)
    @test v7 == 7

    # unwrap
    rr = rpar(mod1(2, Comm.nprocs())) do
        identity(r6)
    end
    @test isa(rr, FunRef{Any})
    r = unwrap(rr)
    @test isa(r, FunRef{Any})
    crr = rcall(getproc(rr)) do
        r = rr[]
        rcall(getproc(r)) do
            r[] == 7
        end
    end
    @test crr
    cr = rcall(getproc(r)) do
        r[] == 7
    end
    @test cr
end

function local_fun_typed()
    # par
    r1 = par(R=Int) do
        inc(1)
    end
    @test isa(r1, FunRef{Int})
    @test islocal(r1)
    @test r1[] == 2

    # rpar
    r3 = rpar(R=Int, mod1(2, Comm.nprocs())) do
        inc(3)
    end
    @test isa(r3, FunRef{Int})
    @test islocal(r3)
    @test r3[] == 4

    # rcall
    v4 = rcall(R=Int, mod1(2, Comm.nprocs())) do
        inc(4)
    end
    @test v4 == 5

    # remote
    r6 = remote(R=Int, mod1(2, Comm.nprocs())) do
        inc(6)
    end
    @test isa(r6, FunRef{Int})
    @test (Comm.nprocs()==1) == islocal(r6)

    # get
    v6 = rcall(R=Int, getproc(r6)) do
        r6[]
    end
    @test v6 == 7

    # make_local
    r7 = make_local(r6)
    @test isa(r7, FunRef{Int})
    @test islocal(r7)
    @test r7[] == 7

    # get_local
    v7 = get_local(r7)
    @test v7 == 7

    # unwrap
    rr = rpar(R=FunRef{Int}, mod1(3, Comm.nprocs())) do
        identity(r6)
    end
    @test isa(rr, FunRef{FunRef{Int}})
    r = unwrap(rr)
    @test isa(r, FunRef{Int})
    crr = rcall(R=Bool, getproc(rr)) do
        r = rr[]
        rcall(R=Bool, getproc(r)) do
            r[] == 7
        end
    end
    @test crr
    cr = rcall(R=Bool, getproc(r)) do
        r[] == 7
    end
    @test cr
end

#function local_mac_untyped()
#    # par
#    r1 = @par inc(1)
#    @test isa(r1, FunRef{Any})
#    @test islocal(r1)
#    @test r1[] == 2
#
#    # rpar
#    r3 = @rpar mod1(2, Comm.nprocs()) inc(3)
#    @test isa(r3, FunRef{Any})
#    @test islocal(r3)
#    @test r3[] == 4
#
#    # rcall
#    v4 = @rcall mod1(2, Comm.nprocs()) inc(4)
#    @test v4 == 5
#
#    # remote
#    r6 = @remote mod1(2, Comm.nprocs()) inc(6)
#    @test isa(r6, FunRef{Any})
#    @test (Comm.nprocs()==1) == islocal(r6)
#
#    # get_cmp
#    v6 = @rcall getproc(r6) r6[]
#    @test v6 == 7
#
#    # make_local
#    r7 = make_local(r6)
#    @test isa(r7, FunRef{Any})
#    @test islocal(r7)
#    @test r7[] == 7
#
#    # get_local
#    v7 = get_local(r7)
#    @test v7 == 7
#
#    # unwrap
#    rr = @rpar mod1(3, Comm.nprocs()) r6
#    @test isa(rr, FunRef{Any})
#    r = unwrap(rr)
#    @test isa(r, FunRef{Any})
#    vrr = rr[]
#    vvrr = @rcall getproc(r6) vrr[]
#    @test vvrr == 7
#    vr = @rcall getproc(r) r[]
#    @test vr == 7
#end

#function local_mac_typed()
#    # par
#    r1 = @par Int inc(1)
#    @test isa(r1, FunRef{Int})
#    @test islocal(r1)
#    @test r1[] == 2
#
#    # rpar
#    r3 = @rpar Int mod1(2, Comm.nprocs()) inc(3)
#    @test isa(r3, FunRef{Int})
#    @test islocal(r3)
#    @test r3[] == 4
#
#    # rcall
#    v4 = @rcall Int mod1(2, Comm.nprocs()) inc(4)
#    @test v4 == 5
#
#    # remote
#    r6 = @remote Int mod1(2, Comm.nprocs()) inc(6)
#    @test isa(r6, FunRef{Int})
#    @test (Comm.nprocs()==1) == islocal(r6)
#
#    # get_cmp
#    v6 = @rcall Int getproc(r6) r6[]
#    @test v6 == 7
#
#    # make_local
#    r7 = make_local(r6)
#    @test isa(r7, FunRef{Int})
#    @test islocal(r7)
#    @test r7[] == 7
#
#    # get_local
#    v7 = get_local(r7)
#    @test v7 == 7
#
#    # unwrap
#    rr = @rpar FunRef{Int} mod1(3, Comm.nprocs()) r6
#    @test isa(rr, FunRef{FunRef{Int}})
#    r = unwrap(rr)
#    @test isa(r, FunRef{Int})
#    vrr = rr[]
#    vvrr = @rcall Int getproc(r6) vrr[]
#    @test vvrr == 7
#    vr = @rcall Int getproc(r) r[]
#    @test vr == 7
#end



function local_unwrap_untyped()
    p1 = mod1(2, Comm.nprocs())
    p2 = mod1(3, Comm.nprocs())
    # Try creating and readying the refs in all possible orders. These are all
    # permutations of the five steps, with the constraint that :creatN must
    # occur before :readyN, and :unwrap after :creat2.
    allsteps = [:creat1, :creat2, :ready1, :ready2, :unwrap]
    for steps in permutations(allsteps)
        function isbefore(a::Symbol, b::Symbol)
            findin(steps, [a])[1] < findin(steps, [b])[1]
        end
        if !isbefore(:creat1, :ready1) continue end
        if !isbefore(:creat2, :ready2) continue end
        if !isbefore(:creat1, :creat2) continue end
        if !isbefore(:creat2, :unwrap) continue end
        rcall(p1) do
            global cond1=Condition()
        end
        rcall(p2) do
            global cond2=Condition()
        end
        local r1, r2, ru
        r1ready = r2ready = ruready = false
        haver1 = haver2 = haveru = false
        for step in steps
            if step == :creat1
                r1 = remote(p1) do
                    global cond1; wait(cond1); 8
                end
                @test typeof(r1) == FunRef{Any}
                haver1 = true
            elseif step == :creat2
                r2 = remote(p2) do
                    global cond2; wait(cond2); r1
                end
                @test typeof(r2) == FunRef{Any}
                haver2 = true
            elseif step == :ready1
                rcall(p1) do
                    global cond1; notify(cond1)
                end
                r1ready = true
                wait(r1)
            elseif step == :ready2
                rcall(p2) do
                    global cond2; notify(cond2)
                end
                r2ready = true
                wait(r2)
            elseif step == :unwrap
                ru = unwrap(r2)
                @test typeof(ru) == FunRef{Any}
                haveru = true
            else
                @assert false
            end
            if haveru
                ruready = r1ready && r2ready
            end
            if ruready
                wait(ru)
            end
            sleep(0.1)
            if haver1
                @test isready(r1) == r1ready
            end
            if haver2
                @test isready(r2) == r2ready
            end
            if haveru
                @test isready(ru) == ruready
            end
            if r1ready
                @test get_local(r1) == 8
            end
            if r1ready && r2ready
                @test get_local(get_local(r2)) == 8
            end
            if ruready
                @test get_local(ru) == 8
            end
        end
        @assert r1ready && r2ready && ruready
    end
end

function local_unwrap_typed()
    p1 = mod1(2, Comm.nprocs())
    p2 = mod1(3, Comm.nprocs())
    # Try creating and readying the refs in all possible orders. These are all
    # permutations of the five steps, with the constraint that :creatN must
    # occur before :readyN, and :unwrap after :creat2.
    allsteps = [:creat1, :creat2, :ready1, :ready2, :unwrap]
    for steps in permutations(allsteps)
        function isbefore(a::Symbol, b::Symbol)
            findin(steps, [a])[1] < findin(steps, [b])[1]
        end
        if !isbefore(:creat1, :ready1) continue end
        if !isbefore(:creat2, :ready2) continue end
        if !isbefore(:creat1, :creat2) continue end
        if !isbefore(:creat2, :unwrap) continue end
        rcall(p1) do
            global cond1=Condition()
        end
        rcall(p2) do
            global cond2=Condition()
        end
        local r1, r2, ru
        r1ready = r2ready = ruready = false
        haver1 = haver2 = haveru = false
        for step in steps
            if step == :creat1
                r1 = remote(R=Int, p1) do
                    global cond1; wait(cond1); 8
                end
                @test typeof(r1) == FunRef{Int}
                haver1 = true
            elseif step == :creat2
                r2 = remote(R=FunRef{Int}, p2) do
                    global cond2; wait(cond2); r1
                end
                @test typeof(r2) == FunRef{FunRef{Int}}
                haver2 = true
            elseif step == :ready1
                rcall(p1) do
                    global cond1; notify(cond1)
                end
                r1ready = true
                wait(r1)
            elseif step == :ready2
                rcall(p2) do
                    global cond2; notify(cond2)
                end
                r2ready = true
                wait(r2)
            elseif step == :unwrap
                ru = unwrap(r2)
                @test typeof(ru) == FunRef{Int}
                haveru = true
            else
                @assert false
            end
            if haveru
                ruready = r1ready && r2ready
            end
            if ruready
                wait(ru)
            end
            sleep(0.1)
            if haver1
                @test isready(r1) == r1ready
            end
            if haver2
                @test isready(r2) == r2ready
            end
            if haveru
                @test isready(ru) == ruready
            end
            if r1ready
                @test get_local(r1) == 8
            end
            if r1ready && r2ready
                @test get_local(get_local(r2)) == 8
            end
            if ruready
                @test get_local(ru) == 8
            end
        end
        @assert r1ready && r2ready && ruready
    end
end



function test_foldable()
    r1 = FunRef(2)
    r2 = FunRef(3)
    @test freduce(+, 0, r1) == 2
    @test freduce(+, 0, r1, r2) == 5

    r3 = remote(()->4, mod1(2,Comm.nprocs()))
    @test freduce(+, 0, r3) == 4
    @test freduce(+, 0, r3, r1) == 6
end

function test_functor()
    r1 = FunRef(2)
    r2 = FunRef(3)
    r3 = remote(()->4, R=Int, mod1(2,Comm.nprocs()))
    @test getproc(r3) == mod1(2,Comm.nprocs())
    fr1 = fmap(R=Int, x->2x, r1)
    fr2 = fmap(R=Int, (x,y)->2x+y, r1, r2)
    fr3 = fmap(R=Int, (x,y)->2x+y, r1, r3)
    fr4 = fmap(R=Int, (x,y)->2x+y, r3, r1)
    @test islocal(fr1)
    @test islocal(fr2)
    @test islocal(fr3)
    @test getproc(fr4) == mod1(2,Comm.nprocs())
    @test fr1[] == 4
    @test fr2[] == 7
    @test fr3[] == 8
    @test get_local(fr4) == 10
end

function test_monad()
    u = munit(FunRef{Int}, 42)
    @test islocal(u)
    @test u[] == 42

    uu = munit(FunRef{FunRef{Int}}, u)
    @test islocal(uu)
    @test uu[][] == 42

    j = mjoin(uu)
    @test j[] == 42

    b = mbind(x::Int->FunRef(x+1.0), FunRef(1), R=FunRef{Float64})
    @test b[] == 2.0

    b = mbind(Fun{FunRef{Float64}}(x->FunRef(x+1.0)), FunRef(1))
    @test b[] == 2.0
end



function main()
    "ParTest.main.0"
    local_fun_untyped()
    "ParTest.main.1"
    local_fun_typed()
    "ParTest.main.2"
    #local_mac_untyped()
    #local_mac_typed()
    local_unwrap_untyped()
    local_unwrap_typed()
    test_foldable()
    test_functor()
    test_monad()
end

end
