module ParTest

using Base.Test

using Comm, Foldable, Functor, Funs, Monad, Par, Refs



function main()
    local_fun_untyped()
    local_fun_typed()
    local_mac_untyped()
    local_mac_typed()
    local_unwrap_untyped()
    local_unwrap_typed()
    test_foldable()
    test_functor()
    test_monad()
end

function local_fun_untyped()
    # par
    r1 = par(inc, 1)
    @test isa(r1, Ref{Any})
    @test islocal(r1)
    @test get(r1) == 2
    
    # rpar
    r3 = rpar(mod1(2, nprocs()), inc, 3)
    @test isa(r3, Ref{Any})
    @test islocal(r3)
    @test get(r3) == 4
    
    # rcall
    v4 = rcall(mod1(2, nprocs()), inc, 4)
    @test v4 == 5
    
    # remote
    r6 = remote(mod1(2, nprocs()), inc, 6)
    @test isa(r6, Ref{Any})
    @test (nprocs()==1) == islocal(r6)
    
    # get
    v6 = rcall(getproc(r6), get, r6)
    @test v6 == 7
    
    # make_local
    r7 = make_local(r6)
    @test isa(r7, Ref{Any})
    @test islocal(r7)
    @test get(r7) == 7
    
    # get_remote
    v7 = get_remote(r7)
    @test v7 == 7
    
    # unwrap
    rr = rpar(mod1(2, nprocs()), identity, r6)
    @test isa(rr, Ref{Any})
    r = unwrap(rr)
    @test isa(r, Ref{Any})
    crr = rcall(getproc(r6), get_cmp, get(rr), 7)
    @test crr
    cr = rcall(getproc(r6), get_cmp, r, 7)
    @test cr
end

function local_fun_typed()
    # par
    r1 = par(R=Int, inc, 1)
    @test isa(r1, Ref{Int})
    @test islocal(r1)
    @test get(r1) == 2
    
    # rpar
    r3 = rpar(R=Int, mod1(2, nprocs()), inc, 3)
    @test isa(r3, Ref{Int})
    @test islocal(r3)
    @test get(r3) == 4
    
    # rcall
    v4 = rcall(R=Int, mod1(2, nprocs()), inc, 4)
    @test v4 == 5
    
    # remote
    r6 = remote(R=Int, mod1(2, nprocs()), inc, 6)
    @test isa(r6, Ref{Int})
    @test (nprocs()==1) == islocal(r6)
    
    # get
    v6 = rcall(R=Int, getproc(r6), get, r6)
    @test v6 == 7
    
    # make_local
    r7 = make_local(r6)
    @test isa(r7, Ref{Int})
    @test islocal(r7)
    @test get(r7) == 7
    
    # get_remote
    v7 = get_remote(r7)
    @test v7 == 7
    
    # unwrap
    rr = rpar(R=Ref{Int}, mod1(3, nprocs()), identity, r6)
    @test isa(rr, Ref{Ref{Int}})
    r = unwrap(rr)
    @test isa(r, Ref{Int})
    crr = rcall(R=Bool, getproc(r6), get_cmp, get(rr), 7)
    @test crr
    cr = rcall(R=Bool, getproc(r6), get_cmp, r, 7)
    @test cr
end

function local_mac_untyped()
    # par
    r1 = @par inc(1)
    @test isa(r1, Ref{Any})
    @test islocal(r1)
    @test get(r1) == 2

    # rpar
    r3 = @rpar mod1(2, nprocs()) inc(3)
    @test isa(r3, Ref{Any})
    @test islocal(r3)
    @test get(r3) == 4
    
    # rcall
    v4 = @rcall mod1(2, nprocs()) inc(4)
    @test v4 == 5
    
    # remote
    r6 = @remote mod1(2, nprocs()) inc(6)
    @test isa(r6, Ref{Any})
    @test (nprocs()==1) == islocal(r6)
    
    # get_cmp
    v6 = @rcall getproc(r6) get(r6)
    @test v6 == 7
    
    # make_local
    r7 = make_local(r6)
    @test isa(r7, Ref{Any})
    @test islocal(r7)
    @test get(r7) == 7
    
    # get_remote
    v7 = get_remote(r7)
    @test v7 == 7
    
    # unwrap
    rr = @rpar mod1(3, nprocs()) r6
    @test isa(rr, Ref{Any})
    r = unwrap(rr)
    @test isa(r, Ref{Any})
    vrr = get(rr)
    vvrr = @rcall getproc(r6) get(vrr)
    @test vvrr == 7
    vr = @rcall getproc(r) get(r)
    @test vr == 7
end

function local_mac_typed()
    # par
    r1 = @par Int inc(1)
    @test isa(r1, Ref{Int})
    @test islocal(r1)
    @test get(r1) == 2

    # rpar
    r3 = @rpar Int mod1(2, nprocs()) inc(3)
    @test isa(r3, Ref{Int})
    @test islocal(r3)
    @test get(r3) == 4
    
    # rcall
    v4 = @rcall Int mod1(2, nprocs()) inc(4)
    @test v4 == 5
    
    # remote
    r6 = @remote Int mod1(2, nprocs()) inc(6)
    @test isa(r6, Ref{Int})
    @test (nprocs()==1) == islocal(r6)
    
    # get_cmp
    v6 = @rcall Int getproc(r6) get(r6)
    @test v6 == 7
    
    # make_local
    r7 = make_local(r6)
    @test isa(r7, Ref{Int})
    @test islocal(r7)
    @test get(r7) == 7
    
    # get_remote
    v7 = get_remote(r7)
    @test v7 == 7
    
    # unwrap
    rr = @rpar Ref{Int} mod1(3, nprocs()) r6
    @test isa(rr, Ref{Ref{Int}})
    r = unwrap(rr)
    @test isa(r, Ref{Int})
    vrr = get(rr)
    vvrr = @rcall Int getproc(r6) get(vrr)
    @test vvrr == 7
    vr = @rcall Int getproc(r) get(r)
    @test vr == 7
end

function inc(i::Integer)
    i+1
end

function get_cmp(ref::Ref, i::Integer)
    get(ref) == i
end



function local_unwrap_untyped()
    p1 = mod1(2, nprocs())
    p2 = mod1(3, nprocs())
    # Try creating and readying the refs in all possible orders. These
    # are all permutations of the five steps, with the constraint that
    # :creatN must occur before :readyN, and :unwrap after :creat2.
    allsteps = [:creat1, :creat2, :ready1, :ready2, :unwrap]
    for steps in permutations(allsteps)
        function isbefore(a::Symbol, b::Symbol)
            findin(steps, [a])[1] < findin(steps, [b])[1]
        end
        if !isbefore(:creat1, :ready1) continue end
        if !isbefore(:creat2, :ready2) continue end
        if !isbefore(:creat1, :creat2) continue end
        if !isbefore(:creat2, :unwrap) continue end
        @rcall p1 (global cond1=Condition())
        @rcall p2 (global cond2=Condition())
        local r1, r2, ru
        r1ready = r2ready = ruready = false
        haver1 = haver2 = haveru = false
        for step in steps
            if step == :creat1
                r1 = @remote p1 (global cond1; wait(cond1); 8)
                @test typeof(r1) == Ref{Any}
                haver1 = true
            elseif step == :creat2
                r2 = @remote p2 (global cond2; wait(cond2); r1)
                @test typeof(r2) == Ref{Any}
                haver2 = true
            elseif step == :ready1
                @rcall p1 (global cond1; notify(cond1))
                r1ready = true
                wait(r1)
            elseif step == :ready2
                @rcall p2 (global cond2; notify(cond2))
                r2ready = true
                wait(r2)
            elseif step == :unwrap
                ru = unwrap(r2)
                @test typeof(ru) == Ref{Any}
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
                @test get_remote(r1) == 8
            end
            if r1ready && r2ready
                @test get_remote(get_remote(r2)) == 8
            end
            if ruready
                @test get_remote(ru) == 8
            end
        end
        @assert r1ready && r2ready && ruready
    end
end

function local_unwrap_typed()
    p1 = mod1(2, nprocs())
    p2 = mod1(3, nprocs())
    # Try creating and readying the refs in all possible orders. These
    # are all permutations of the five steps, with the constraint that
    # :creatN must occur before :readyN, and :unwrap after :creat2.
    allsteps = [:creat1, :creat2, :ready1, :ready2, :unwrap]
    for steps in permutations(allsteps)
        function isbefore(a::Symbol, b::Symbol)
            findin(steps, [a])[1] < findin(steps, [b])[1]
        end
        if !isbefore(:creat1, :ready1) continue end
        if !isbefore(:creat2, :ready2) continue end
        if !isbefore(:creat1, :creat2) continue end
        if !isbefore(:creat2, :unwrap) continue end
        @rcall p1 (global cond1=Condition())
        @rcall p2 (global cond2=Condition())
        local r1, r2, ru
        r1ready = r2ready = ruready = false
        haver1 = haver2 = haveru = false
        for step in steps
            if step == :creat1
                r1 = @remote Int p1 (global cond1; wait(cond1); 8)
                @test typeof(r1) == Ref{Int}
                haver1 = true
            elseif step == :creat2
                r2 = @remote Ref{Int} p2 (global cond2; wait(cond2); r1)
                @test typeof(r2) == Ref{Ref{Int}}
                haver2 = true
            elseif step == :ready1
                @rcall p1 (global cond1; notify(cond1))
                r1ready = true
                wait(r1)
            elseif step == :ready2
                @rcall p2 (global cond2; notify(cond2))
                r2ready = true
                wait(r2)
            elseif step == :unwrap
                ru = unwrap(r2)
                @test typeof(ru) == Ref{Int}
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
                @test get_remote(r1) == 8
            end
            if r1ready && r2ready
                @test get_remote(get_remote(r2)) == 8
            end
            if ruready
                @test get_remote(ru) == 8
            end
        end
        @assert r1ready && r2ready && ruready
    end
end



function test_foldable()
    r1 = ref(2)
    r2 = ref(3)
    @test freduce(+, 0, r1) == 2
    @test freduce(+, 0, r1, r2) == 5
    
    r3 = @remote mod1(2,nprocs()) 4
    @test freduce(+, 0, r3) == 4
    @test freduce(+, 0, r3, r1) == 6
end

function test_functor()
    r1 = ref(2)
    r2 = ref(3)
    r3 = @remote Int mod1(2,nprocs()) 4
    @test getproc(r3) == mod1(2,nprocs())
    fr1 = fmap(R=Int, x->2*x, r1)
    fr2 = fmap(R=Int, (x,y)->2*x+y, r1, r2)
    fr3 = fmap(R=Int, (x,y)->2*x+y, r1, r3)
    fr4 = fmap(R=Int, (x,y)->2*x+y, r3, r1)
    @test islocal(fr1)
    @test islocal(fr2)
    @test islocal(fr3)
    @test getproc(fr4) == mod1(2,nprocs())
    @test get(fr1) == 4
    @test get(fr2) == 7
    @test get(fr3) == 8
    @test get_remote(fr4) == 10
end

function test_monad()
    u = munit(Ref{Int}, 42)
    @test islocal(u)
    @test get(u) == 42
    
    uu = munit(Ref{Ref{Int}}, u)
    @test islocal(uu)
    @test get(get(uu)) == 42
    
    j = mjoin(uu)
    @test get(j) == 42
    
    b = mbind(ref(1), x::Int->ref(x+1.0), R=Ref{Float64})
    @test get(b) == 2.0
    
    b = mbind(ref(1), Fun{Ref{Float64}}(x->ref(x+1.0)))
    @test get(b) == 2.0
end



run_main(main)

end
