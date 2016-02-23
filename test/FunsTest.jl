module FunsTest

using Funs
using Base.Test



function inc(i::Integer)
    i+1
end

immutable Inc
    i::Int
    Inc(i) = new(i+1)
end

incf = Fun{Int}(inc)



# untyped functions
let
    # Function
    v1 = fcall(inc, 1)
    @test v1 == 2

    # DataType
    v2 = fcall(Inc, 2)
    @test v2.i == 3

    # Fun
    v3 = fcall(incf, 3)
    @test v3 == 4
end

# typed function
let
    # Function
    v1 = fcall(R=Int, inc, 1)
    @test v1 == 2

    # DataType
    v2 = fcall(R=Inc, Inc, 2)
    @test v2.i == 3

    # Fun
    v3 = fcall(R=Int, incf, 3)
    @test v3 == 4
end

# untyped macros
let
    # Function
    v1 = @fcall inc(1)
    @test v1 == 2

    # DataType
    v2 = @fcall Inc(2)
    @test v2.i == 3

    # Fun
    v3 = @fcall incf(3)
    @test v3 == 4
end

# typed macros
let
    # Function
    v1 = @fcall Int inc(1)
    @test v1 == 2

    # DataType
    v2 = @fcall Inc Inc(2)
    @test v2.i == 3

    # Fun
    v3 = @fcall Int incf(3)
    @test v3 == 4
end

end
