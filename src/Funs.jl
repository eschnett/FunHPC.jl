module Funs

using Base.Meta

import Base: call, eltype

export Fun, Callable
export fcall, @fcall

# TODO: Use Base.return_types
eltype(f::Function) = Any
fcall(f::Function, args...; R::Type=Any) = f(args...)::R

# eltype(f::DataType) = f
fcall(f::DataType, args...; R::Type=f) = f(args...)::R

immutable Fun{T}
    fun::Function
end
eltype{R}(f::Fun{R}) = R
fcall{T}(f::Fun{T}, args...; R::Type=T) = f.fun(args...)::R
# call{T}(f::Fun{T}, args...; R::Type=T) = fcall(f, args..., R=R)
(f::Fun{T}){T}(args...; R::Type=T) = fcall(f, args..., R=R)

typealias Callable Union{Function, DataType, Fun}
# fcall, eltype

iscall(expr) = isexpr(expr, :call)
# Note: The called function is args[1], the arguments are args[2:end]
getcallargs(expr) = (@assert iscall(expr); expr.args)

macro fcall(args...)
    if length(args) == 1
        (expr,) = args
        callargs = getcallargs(expr)
        esc(:(fcall($(callargs...))))
    elseif length(args) == 2
        (R, expr) = args
        callargs = getcallargs(expr)
        esc(:(fcall(R=$R, $(callargs...))))
    else
        error("Expected: @fcall [<type>] <f>(<args>...)")
    end
end

end
