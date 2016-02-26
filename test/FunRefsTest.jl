module FunRefsTest

using Comm, GIDs, FunRefs
using Base.Test

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
    ri = FunRef{T}(i)
    @test ri[] == i
    rn = FunRef{Union{}}()
    global DONE = false
    rexec(mod1(2, nprocs())) do
        remote1(i, ri)
    end
    while !DONE yield() end
end

# Test remote garbage collection
function test_remote(do_gc::Bool)
    # Use a nested function to ensure that ri is garbage collected
    function inner()
        i = 1
        ri = FunRef(i)
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
    ri = FunRef(i)
    @test isready(ri)
    @test islocal(ri)
    @test ri[] == i
    ri = FunRef{Int}()
    @test !isready(ri)
    ri[] = i
    @test isready(ri)
    @test islocal(ri)
    @test ri[] == i
    r0 = FunRef{Void}()
    @test !isready(r0)
    global FUTURE_SET = false
    global FUTURE_DONE = false
    rexec(mod1(2, nprocs())) do
        future_continued(ri, r0)
    end
    while !FUTURE_SET yield() end
    r0[] = nothing
    while !FUTURE_DONE yield() end
end



function remote1(i::Int, ri::FunRef)
    @test getproc(ri) == 1
    @test islocal(ri) == (myproc()==1)
    rexec(getproc(ri)) do
        remote2(i, ri)
    end
end

function remote2(i::Int, ri::FunRef)
    @test islocal(ri)
    @test ri[] == i
    global DONE = true
end

function manyrefs(i::Int, ri::FunRef, count::Int, do_gc::Bool)
    @assert count>0
    if do_gc gc() end
    @test !islocal(ri) || ri[] == i
    if count == 1
        rexec(1) do
            inc()
        end
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
    if count1>0
        rexec(proc1) do
            manyrefs(i, ri, count1, do_gc)
        end
    end
    if count2>0
        rexec(proc2) do
            manyrefs(i, ri, count2, do_gc)
        end
    end
    j = i+1
    rj = FunRef(j)
    if count3>0
        rexec(proc3) do
            manyrefs(j, rj, count3, do_gc)
        end
    end
end

function inc()
    global COUNT += 1
end

function check_refs()
    gc()
    sleep(1)
    @test isempty(GIDs.mgr())
    rexec(1) do
        inc()
    end
end

function future_continued(ri::FunRef, r0::FunRef)
    @test isready(ri)
    @test islocal(ri) == (nprocs()==1)
    rj = typeof(ri)()
    @test !isready(rj)
    set_from_ref!(rj, ri)
    @test isready(rj)
    @test islocal(rj) == (nprocs()==1)
    @test !isready(r0)
    rexec(1) do
        future_set()
    end
    wait(r0)
    rexec(1) do
        future_done()
    end
end

function future_set()
    global FUTURE_SET = true
end

function future_done()
    global FUTURE_DONE = true
end



main()

end
