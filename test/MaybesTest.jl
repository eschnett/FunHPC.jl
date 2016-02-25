module MaybesTest

using Funs, Maybes
using Base.Test

function main()
    test_basic()
    test_foldable()
    test_functor()
    test_monad()
end

function test_basic()
    m0 = Maybe{Int}()
    m1 = Maybe{Int}(42)
    m2 = just(42)

    @test !isjust(m0)
    @test isnothing(m0)
    @test eltype(m0) == Int
    @test m0 == Maybe{Int}()
    @test m0 != Maybe{Int}(43)
    @test m0 != m1
    @test length(m0) == 0
    ms = [m for m in m0]
    @test isempty(ms)

    @test isjust(m1)
    @test !isnothing(m1)
    @test eltype(m1) == Int
    @test m1 == Maybe{Int}(42)
    @test m1 != Maybe{Int}(43)
    @test m1 != m0
    @test m1 == m2
    @test length(m1) == 1
    ms = [m for m in m1]
    @test !isempty(ms)
    @test ms == [42]

    @test typeof(m2) == Maybe{Int}

    @test maybe(0, x->x+1, m0) == 0
    @test maybe(0, x->x+1, m1) == 43
    @test fromjust(m1) == 42
    @test frommaybe(43, m0) == 43
    @test frommaybe(43, m1) == 42

    @test arrayToMaybe(Int[]) == Maybe{Int}()
    @test arrayToMaybe([42]) == just(42)
    @test arrayToMaybe([42, 43]) == just(42)
    @test maybeToArray(m0) == Int[]
    @test maybeToArray(m1) == Int[42]

    @test catMaybes([m0, m1, m2]) == [42, 42]
    @test mapMaybe(R=Int, x->x+1, [m0, m1, m2]) == [43, 43]

    @test string(m0) == "(?)"
    @test string(m1) == "(?42)"
end

function test_foldable()
    m0 = Maybe{Int}()
    m1 = Maybe{Int}(2)
    m2 = Maybe{Int}(3)
    @test freduce(+, 0, m0) == 0
    @test freduce(+, 0, m1) == 2
    @test freduce(+, 0, m1, m2) == 5
end

function test_functor()
    m0 = Maybe{Int}()
    m1 = Maybe{Int}(2)
    m2 = Maybe{Int}(3)
    @test fmap(R=Int, x->2*x, m0) == Maybe{Int}()
    @test fmap(R=Int, x->2*x, m1) == Maybe{Int}(4)
    @test fmap(R=Int, (x,y)->2*x+y, m1, m2) == Maybe{Int}(7)
end

function test_monad()
    u = munit(Maybe{Int}, 42)
    @test u == just(42)

    uu = munit(Maybe{Maybe{Int}}, u)
    @test uu == just(just(42))

    j = mjoin(uu)
    @test j == just(42)

    b = mbind(just(1), x::Int->just(x+1.0), R=Maybe{Float64})
    @test b == just(2.0)

    b = mbind(just(1), Fun{Maybe{Float64}}(x->just(x+1.0)))
    @test b == just(2.0)

    z = mzero(Maybe{Int})
    @test isempty(z)
    @test z == Maybe{Int}()

    p1 = mplus(Set([1,2]))
    p2 = mplus(Set([1,2]), Set([3,4]))
    p3 = mplus(Set([1,2]), Set([3,4]), Set([5,6]))
    @test p1 == Set([1,2])
    @test p2 == Set([1,2,3,4])
    @test p3 == Set([1,2,3,4,5,6])
end

main()

end
