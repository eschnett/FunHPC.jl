module FoldableTest

using Foldable
using Base.Test

function main()
    # Array
    let
        xs = [1,2,4,8,16]
        ys = [1,2,3,4,5]
        @test freduce(+, 0, xs) == 31
        @test freduce((r,x,y) -> r+x*y, 0, xs, ys) == 129
        x2s = [1 2 4; 8 16 32]
        y2s = [1 2 3; 4 5 6]
        @test freduce(+, 0, x2s) == 63
        @test freduce((r,x,y) -> r+x*y, 0, x2s, y2s) == 321
    end
    
    # Set
    let
        xs = Set([1,2,4,8,16])
        @test freduce(+, 0, xs) == 31
    end
    
    # Tuple
    let
        xs = (1,2,4,8,16)
        ys = (1,2,3,4,5)
        @test freduce(+, 0, xs) == 31
        @test freduce((x,y,z) -> x+y*z, 0, xs, ys) == 129
    end
end

end
