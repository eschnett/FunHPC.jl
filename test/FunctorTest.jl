module FunctorTest

using Funs, Functor
using Base.Test

function main()
    # Array
    let
        xs = [1,2,4,8,16]
        ys = [1,2,3,4,5]
        @test fmap(x->2*x, xs) == [2,4,8,16,32]
        @test fmap(+, xs, ys) == [2,4,7,12,21]
        x2s = [1 2 4; 8 16 32]
        y2s = [1 2 3; 4 5 6]
        @test fmap(x->2*x, x2s) == [2 4 8; 16 32 64]
        @test fmap(+, x2s, y2s) == [2 4 7; 12 21 38]
    end
    
    # Fun (Callable)
    let
        f = Fun{Float64}(x::Int -> float(x)+0.5)
        g = Fun{Complex{Float64}}(x::Float64 -> x+im)
        @test fmap(g, f)(12) == 12.5+im
        f2 = Fun{Int}(x::Int -> x+1)
        g2 = Fun{Complex{Float64}}((x::Float64, y::Int) -> x+float(y)*im)
        @test fmap(g2, f, f2)(12,13) == 12.5+14.0im
    end
    
    # Set
    let
        xs = Set([1,2,4,8,16])
        @test fmap(x->2*x, xs) == Set([2,4,8,16,32])
    end
    
    # Tuple
    let
        xs = (1,2,4,8,16)
        ys = (1,2,3,4,5)
        @test fmap(x->2*x, xs) == (2,4,8,16,32)
        @test fmap(+, xs, ys) == (2,4,7,12,21)
    end
end

end
