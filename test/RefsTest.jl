module RefsTest

using Base.Test

using Comm, GIDs, Refs

function main()
    test_basic(Any)
    test_basic(Int)
    test_remote(true)
    test_remote(false)
    test_future()
end

# Test basic operations
function test_basic(T::Type)
    i = 1
    ri = Ref{T}(i)
    @test get(ri) == i
    rn = Ref{None}()
    global DONE = false
    rexec(mod1(2, nprocs()), remote1, i, ri)
    while !DONE yield() end
end

# Test remote garbage collection
function test_remote(do_gc::Bool)
    # Use a nested function to ensure that ri is garbage collected
    function inner()
        i = 1
        ri = ref(i)
        maxcount = 1000
        global COUNT = 0
        manyrefs(i, ri, maxcount, do_gc)
        while COUNT<maxcount yield() end
        sleep(1)
        @test COUNT==maxcount
    end
    inner()
    global COUNT = 0
    rexec_everywhere(check_refs)
    while COUNT<nprocs() yield() end
    sleep(1)
end

# Test future behaviour
function test_future()
    i = 1
    ri = ref(i)
    @test isready(ri)
    @test islocal(ri)
    @test get(ri) == i
    ri = Ref{Int}()
    @test !isready(ri)
    set!(ri, i)
    @test isready(ri)
    @test islocal(ri)
    @test get(ri) == i
    r0 = Ref{Nothing}()
    @test !isready(r0)
    global FUTURE_SET = false
    global FUTURE_DONE = false
    rexec(mod1(2, nprocs()), future_continued, ri, r0)
    while !FUTURE_SET yield() end
    set!(r0, nothing)
    while !FUTURE_DONE yield() end
end



function remote1(i::Int, ri::Ref)
    @test getproc(ri) == 1
    @test islocal(ri) == (myproc()==1)
    rexec(getproc(ri), remote2, i, ri)
end

function remote2(i::Int, ri::Ref)
    @test islocal(ri)
    @test get(ri) == i
    global DONE = true
end

function manyrefs(i::Int, ri::Ref, count::Int, do_gc::Bool)
    @assert count>0
    if do_gc gc() end
    @test !islocal(ri) || get(ri) == i
    if count == 1
        rexec(1, inc)
        return
    end
    proc1 = rand(1:nprocs())
    proc2 = rand(1:nprocs())
    proc3 = rand(1:nprocs())
    counta = rand(0:count)
    countb = rand(0:count)
    count1 = min(counta, countb)
    count2 = max(counta, countb) - count1
    count3 = count - (count1 + count2)
    @assert count1 + count2 + count3 == count
    if count1>0 rexec(proc1, manyrefs, i, ri, count1, do_gc) end
    if count2>0 rexec(proc2, manyrefs, i, ri, count2, do_gc) end
    j = i+1
    rj = ref(j)
    if count3>0 rexec(proc3, manyrefs, j, rj, count3, do_gc) end
end

function inc()
    global COUNT += 1
end

function check_refs()
    gc()
    sleep(1)
    @test isempty(GIDs.mgr())
    rexec(1, inc)
end

function future_continued(ri::Ref, r0::Ref)
    @test isready(ri)
    @test islocal(ri) == (nprocs()==1)
    rj = typeof(ri)()
    @test !isready(rj)
    set_from_ref!(rj, ri)
    @test isready(rj)
    @test islocal(rj) == (nprocs()==1)
    @test !isready(r0)
    rexec(1, future_set)
    wait(r0)
    rexec(1, future_done)
end

function future_set()
    global FUTURE_SET = true
end

function future_done()
    global FUTURE_DONE = true
end



run_main(main)

end
