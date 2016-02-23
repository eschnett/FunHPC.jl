module Maybes

using Foldable, Functor, Funs, Monad

import Base.show
import Base.eltype, Base.==
import Base.serialize, Base.deserialize
import Base.length, Base.start, Base.next, Base.done, Base.isempty
import Foldable.freduce
import Functor.fmap
import Monad.tycon, Monad.valtype
import Monad.munit, Monad.mjoin, Monad.mbind, Monad.mzero, Monad.mplus

export Maybe
export just
export isjust, isnothing
export maybe, fromjust, frommaybe
export arrayToMaybe, maybeToArray
export catMaybes, mapMaybe
export show
export eltype, ==
export serialize, deserialize
export length, start, next, done, isempty
export freduce
export fmap
export tycon, valtype
export munit, mjoin, mbind, mzero, mplus



immutable Maybe{T}
    isjust::Bool
    value::T
    Maybe() = new(false)
    Maybe(value) = new(true,value)
end
just{T}(value::T) = Maybe{T}(value)

isjust(m::Maybe) = m.isjust
isnothing(m::Maybe) = !isjust(m)

maybe{T}(zero, f::Callable, m::Maybe{T}; R::Type=eltype(f)) =
    isjust(m) ? call(f, m.value)::R : zero::R

fromjust(m::Maybe) = (@assert isjust(m); m.value)
frommaybe{T}(zero, m::Maybe{T}) = isjust(m) ? m.value : zero::T

arrayToMaybe{T}(xs::Array{T,1}) = isempty(xs) ? Maybe{T}() : just(xs[1])
maybeToArray{T}(m::Maybe{T}) = isnothing(m) ? T[] : T[m.value]

function catMaybes{T}(xs::Array{Maybe{T},1})
    rs = T[]
    for x in xs
        maybe(rs, (r->push!(rs,r)), x)
    end
    rs
end

function mapMaybe{MT}(f::Callable, xs::Array{MT,1}; R::Type=eltype(f))
    rs = R[]
    for x in xs
        maybe(rs, (r->push!(rs,call(R=R,f,r))), x)
    end
    rs
end



show(io::IO, m::Maybe) = print(io, maybe("(?)", v->"(?$v)", m))

eltype{T}(m::Maybe{T}) = T

function =={T}(m1::Maybe{T}, m2::Maybe{T})
    if isnothing(m1) && isnothing(m2) return true end
    if isnothing(m1) || isnothing(m2) return false end
    fromjust(m1) == fromjust(m2)
end

function serialize{T}(s, m::Maybe{T})
    Base.serialize_type(s, Maybe{T})
    write(s, m.isjust)
    if m.isjust
        write(s, fromjust(m))
    end
end
function deserialize{T}(s, ::Type{Maybe{T}})
    isjust = read(s, Bool)
    if isjust
        value = read(s, T)
        Maybe{T}(value)
    else
        Maybe{T}()
    end
end

length(m::Maybe) = int(isjust(m))
start(m::Maybe) = isnothing(m)
next(m::Maybe, i) = fromjust(m), true
done(m::Maybe, i) = i
isempty(m::Maybe) = isnothing(m)




function freduce(op::Callable, zero, m::Maybe, ns::Maybe...; R::Type=eltype(op))
    [@assert isjust(n) == isjust(m) for n in ns]
    if isnothing(m) return zero::R end
    @call R op(zero, fromjust(m), map(fromjust, ns)...)
end

function fmap(f::Callable, m::Maybe, ns::Maybe...; R::Type=eltype(f))
    [@assert isjust(n) == isjust(m) for n in ns]
    if isnothing(m) return Maybe{R}() end
    Maybe{R}(@call R f(fromjust(m), map(fromjust, ns)...))
end

tycon{T,R}(::Type{Maybe{T}}, ::Type{R}) = Maybe{R}
valtype{T}(::Type{Maybe{T}}) = T

munit{T}(::Type{Maybe{T}}, x) = Maybe{T}(x)
mjoin{T}(xss::Maybe{Maybe{T}}) = frommaybe(Maybe{T}(), xss)
mbind{T}(xs::Maybe{T}, f::Callable; R::Type=eltype(f)) = mjoin(fmap(R=R, f, xs))

mzero{T}(::Type{Maybe{T}}) = Maybe{T}()
mplus{T}(xs::Maybe{T}) = xs
mplus{T}(xs::Maybe{T}, ys::Maybe{T}, zss::Maybe{T}...) =
    isjust(xs) ? xs : mplus(ys, zss...)

end
