module StencilFunctorTest

using StencilFunctor
using Base.Test

function main()
    # Array
    let
        diff(c, bm, bp) = bp - bm
        bc(c, dir) = c
        @test stencil_fmap(diff, bc, Int[], 0, 1) == Int[]
        @test stencil_fmap(diff, bc, [1], 0, 2) == [2]
        @test stencil_fmap(diff, bc, [1,2], 0, 3) == [2,2]
        @test stencil_fmap(diff, bc, [1,2,3,4,5], 0, 6) == [2,2,2,2,2]
    end
end

end
