module GIDsTest

using Comm, GIDs
using Base.Test

function test()
    t = "hello"
    gid = makegid(t)
    t = nothing
    @test islocal(gid)
    @test !isnull(gid)
    @test hasobj(gid)
    @test getobj(gid) == "hello"
    free(gid)
    sleep(1)
    @test !hasobj(gid)

    gid = nullgid()
    @test isnull(gid)
    @test islocal(gid)

    gid = makegid(t)
    @test gid.proc == 1
    @test islocal(gid)
    @test !isnull(gid)
    global TERMINATE = false
    rexec(mod1(2, Comm.nprocs())) do
        test2(gid)
    end
    while !TERMINATE yield() end
end

function test2(gid::GID)
    @test gid.proc == 1
    @test islocal(gid) == (Comm.myproc()==1)
    @test !isnull(gid)
    free(gid)
    rexec(1) do
        test3(gid)
    end
end

function test3(gid::GID)
    @test gid.proc == 1
    @test islocal(gid)
    @test !isnull(gid)
    sleep(1)
    @test !hasobj(gid)
    global TERMINATE = true
end

function main()
    test()
end

end
