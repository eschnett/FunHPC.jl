module MonadTest

using Funs, Monad
using Base.Test

function main()
    # Array{T,0}
    let
        u = munit(Array{Int,0}, 42)
        @test length(u) == 1
        @test isa(u, Array{Int,0})
        @test u == fill(42)
    
        uu = munit(Array{Array{Int,0},0}, u)
        @test length(uu) == 1
        @test isa(uu, Array{Array{Int,0},0})
        @test uu[1] == fill(42)
    
        j = mjoin(uu)
        @test length(j) == 1
        @test isa(j, Array{Int,0})
        @test j == fill(42)
    
        b = mbind(x::Int->fill(x+1), fill(1), R=Array{Int,0})
        @test b == fill(2)
    
        b = mbind(Fun{Array{Int,0}}(x::Int->fill(x+1)), fill(1))
        @test b == fill(2)
    end
    
    # Array{T,1}
    let
        u = munit(Array{Int,1}, 42)
        @test length(u) == 1
        @test isa(u, Array{Int,1})
        @test u == [42]
    
        uu = munit(Array{Array{Int,1},1}, u)
        @test length(uu) == 1
        @test isa(uu, Array{Array{Int,1},1})
        @test uu[1] == [42]
    
        j = mjoin(uu)
        @test length(j) == 1
        @test isa(j, Array{Int,1})
        @test j == [42]
    
        a = Array(Array{Int,1}, 2)
        a[1] = [1,2]
        a[2] = [3,4]
        @test isa(a, Array{Array{Int,1},1})
        j2 = mjoin(a)
        @test j2 == [1,2,3,4]
    
        b = mbind(x::Int->Int[x,x+1], [1,2], R=Array{Int,1})
        @test b == [1,2,2,3]
    
        b = mbind(Fun{Array{Int,1}}(x::Int->Int[x,x+1]), [1,2])
        @test b == [1,2,2,3]
    
        z = mzero(Array{Int,1})
        @test isempty(z)
        @test isa(z, Array{Int,1})
        @test size(z) == (0,)
    
        p1 = mplus([1,2])
        p2 = mplus([1,2], [3,4])
        p3 = mplus([1,2], [3,4], [5,6])
        @test p1 == [1,2]
        @test p2 == [1,2,3,4]
        @test p3 == [1,2,3,4,5,6]
    end
    
    # Array{T,2}
    let
        u = munit(Array{Int,2}, 42)
        @test size(u) == (1,1)
        @test u[1] == 42
    
        uu = munit(Array{Array{Int,2},2}, u)
        @test size(uu) == (1,1)
        @test uu[1] == u
    
        j = mjoin(uu)
        @test size(j) == (1,1)
        @test j[1] == 42
    
        a = Array(Array{Int,2}, 2,2)
        a[1] = [11 12; 13 14]
        a[2] = [21 22; 23 24]
        a[3] = [31 32; 33 34]
        a[4] = [41 42; 43 44]
        @test isa(a, Array{Array{Int,2},2})
        j2 = mjoin(a)
        @test j2 == [[11 12; 13 14] [31 32; 33 34]; [21 22; 23 24] [41 42; 43 44]]
    
        b = mbind(x::Int->Int[x x+1; 2*x 2*x+1], [1 2; 3 4], R=Array{Int,2})
        @test b == [[1 2; 2 3] [2 3; 4 5]; [3 4; 6 7] [4 5; 8 9]]
    
        z = mzero(Array{Int,2})
        @test isempty(z)
        @test isa(z, Array{Int,2})
        @test size(z) == (0,0)
    
        p1 = mplus([1 2; 3 4])
        p2 = mplus([1 2; 3 4], [5 6; 7 8])
        p3 = mplus([1 2; 3 4], [5 6; 7 8], [9 10; 11 12])
        @test p1 == [1 2; 3 4]
        @test p2 == [1 2; 3 4; 5 6; 7 8]
        @test p3 == [1 2; 3 4; 5 6; 7 8; 9 10; 11 12]
    end
    
    # Fun
    let
        u = munit(Fun{Int}, 42)
        @test isa(u, Fun{Int})
        @test fcall(u,nothing) == 42
    
        uu = munit(Fun{Fun{Int}}, u)
        @test isa(uu, Fun{Fun{Int}})
        @test fcall(fcall(uu,nothing),nothing) == 42
    
        j = mjoin(uu)
        @test isa(j, Fun{Int})
        @test fcall(j,nothing) == 42
    
        inc = Fun{Int}(x->x+1)
        mul = Fun{Fun{Float64}}(x->Fun{Float64}(y->float(x*y)))
        b = mbind(mul, inc)
        @test isa(b, Fun{Float64})
        @test fcall(b,1) == 2.0
        @test fcall(b,2) == 6.0
        @test fcall(b,3) == 12.0
    
        b = mbind(x->Fun{Float64}(y->float(x*y)), inc, R=Fun{Float64})
        @test isa(b, Fun{Float64})
        @test fcall(b,1) == 2.0
        @test fcall(b,2) == 6.0
        @test fcall(b,3) == 12.0
    end
    
    # Set
    let
        u = munit(Set{Int}, 42)
        @test length(u) == 1
        @test isa(u, Set{Int})
        @test u == Set([42])
    
        uu = munit(Set{Set{Int}}, u)
        @test length(uu) == 1
        @test isa(uu, Set{Set{Int}})
        @test uu == Set([Set([42])])
    
        j = mjoin(uu)
        @test length(j) == 1
        @test isa(j, Set{Int})
        @test j == Set([42])
    
        s = Set([Set([1,2]), Set([3,4])])
        @test isa(s, Set{Set{Int}})
        j2 = mjoin(s)
        @test j2 == Set([1,2,3,4])
    
        b = mbind(x::Int->Set(Int[x,x+1]), Set([1,2]), R=Set{Int})
        @test b == Set([1,2,2,3])
    
        b = mbind(Fun{Set{Int}}(x::Int->Set(Int[x,x+1])), Set([1,2]))
        @test b == Set([1,2,2,3])
    
        z = mzero(Set{Int})
        @test isempty(z)
        @test isa(z, Set{Int})
    
        p1 = mplus(Set([1,2]))
        p2 = mplus(Set([1,2]), Set([3,4]))
        p3 = mplus(Set([1,2]), Set([3,4]), Set([5,6]))
        @test p1 == Set([1,2])
        @test p2 == Set([1,2,3,4])
        @test p3 == Set([1,2,3,4,5,6])
    end
end

end
