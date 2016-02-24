module MultiDictsTest

using MultiDicts
using Base.Test

function test{K,V}(::Type{K}, ::Type{V})
    @assert Char <: K
    @assert Int <: V
    d = MultiDict{K,V}()
    @test isempty(d)
    d['a'] = 1
    @test d['a'] == 1
    d['b'] = 2
    @test d['b'] == 2
    d['a'] = 1
    @test d['a'] == 1
    addindex!(d, 'b')
    @test d['b'] == 2
    i = get!(d, 'a', 2)
    @test i == 1
    j = get!(d, 'c', 3)
    @test j == 3
    delete!(d, 'a')
    @test d['a'] == 1
    delete!(d, 'a')
    @test !haskey(d, 'a')
    @test haskey(d, 'c')
    delete!(d, 'c')
    @test !haskey(d, 'c')
    @test !isempty(d)
    empty!(d)
    @test isempty(d)
end

test(Char, Int)
test(Char, Any)
test(Any, Int)
test(Any, Any)

end
