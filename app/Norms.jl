module Norms

# A norm

using Base.Test

import Base.+, Base.norm

export Norm
export norm, +
export avg, norm2

immutable Norm
    sum::Float64
    sum2::Float64
    count::Float64
    min::Float64
    max::Float64
    maxabs::Float64
end
Norm() = Norm(0.0, 0.0, 0.0, Inf, -Inf, 0.0)

norm(val::Float64) = Norm(val, val*val, 1.0, val, val, abs(val))
+(x::Norm, y::Norm) = Norm(x.sum + y.sum, x.sum2 + y.sum2, x.count + y.count,
                           min(x.min, y.min), max(x.max, y.max),
                           max(x.maxabs, y.maxabs))

@test norm(+2.0) + norm(+3.0) == Norm( 5.0, 13.0, 2.0,  2.0,  3.0, 3.0)
@test norm(+2.0) + norm(-3.0) == Norm(-1.0, 13.0, 2.0, -3.0,  2.0, 3.0)
@test norm(-2.0) + norm(+3.0) == Norm( 1.0, 13.0, 2.0, -2.0,  3.0, 3.0)
@test norm(-2.0) + norm(-3.0) == Norm(-5.0, 13.0, 2.0, -3.0, -2.0, 3.0)

avg(x::Norm) = x.sum / x.count
norm2(x::Norm) = sqrt(x.sum2 / x.count)

@test avg(norm(2.0)) == 2.0
@test norm2(norm(2.0)) == 2.0

end
