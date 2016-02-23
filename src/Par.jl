module Par

using Comm, GIDs, Foldable, Functor, Funs, Monad, Refs

import Base.eltype
import Foldable.freduce
import Functor.fmap
import Monad.tycon, Monad.valtype, Monad.munit, Monad.mjoin, Monad.mbind

export par, @par
export rpar, rcall, @rpar, @rcall
export make_local, get_remote
export unwrap
export remote, @remote
export freduce
export fmap
export tycon, valtype, munit, mjoin, mbind



resc(expr) = esc(Base.localize_vars(expr, false))
# # Return an iterable consisting of a Callable and arguments,
# # corresponding to the content of args of a call Expr
# function make_callargs(expr)
#     if false && Funs.iscall(expr)
#         # Optimize calls by not wrapping them in a lambda expression
#         Funs.getcallargs(expr)
#     else
#         {:(()->$expr)}
#     end
# end



function par(f::Callable, args...; R::Type=eltype(f))
    r = Ref{R}()
    @schedule set!(r, call(f, args...))
    r::Ref{R}
end

macro par(args...)
    if length(args) == 1
        (expr,) = args
        resc(:(par(()->$expr)))
    elseif length(args) == 2
        (R, expr) = args
        resc(:(par(R=$R, ()->$expr)))
    else
        error("Expected: @par [<type>] <expr>)")
    end
end



function rpar(ref::Ref, f::Callable, args...; R::Type=eltype(f))
    r = Ref{R}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref), rpar2, rgid, f, args)
    r::Ref{R}
end
function rpar(p::Integer, f::Callable, args...; R::Type=eltype(f))
    r = Ref{R}()
    rgid = makegid(r)
    rexec(p, rpar2, rgid, f, args)
    r::Ref{R}
end
function rpar2(rgid::GID, f::Callable, args)
    rexec(rgid.proc, rpar3, rgid, call(f, args...))
end
function rpar3(rgid::GID, res::Any)
    r = getobj(rgid)
    free(rgid)
    set!(r, res)
end

# TODO: Introduce LocalRef (aka Future) that does not obtain a GID for
# the item
# TODO: Obtain GID lazily, only when needed?
function rcall(p::Union(Integer,Ref), f::Callable, args...; R::Type=eltype(f))
    get(rpar(R=R, p, f, args...))::R
end

macro rpar(args...)
    if length(args) == 2
        (p, expr) = args
        resc(:(rpar($p, ()->$expr)))
    elseif length(args) == 3
        (R, p, expr) = args
        resc(:(rpar(R=$R, $p, ()->$expr)))
    else
        error("Expected: @rpar [<type>] <proc> <expr>)")
    end
end

macro rcall(args...)
    if length(args) == 2
        (p, expr) = args
        resc(:(rcall($p, ()->$expr)))
    elseif length(args) == 3
        (R, p, expr) = args
        resc(:(rcall(R=$R, $p, ()->$expr)))
    else
        error("Expected: @rcall [<type>] <proc> <expr>)")
    end
end



function make_local{R}(ref::Ref{R})
    rpar(R=R, ref, get, ref)::Ref{R}
end
function get_remote{R}(ref::Ref{R})
    get(make_local(ref))::R
end



function unwrap(ref::Ref{Any})
    r = Ref{Any}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref), unwrap2, rgid, ref)
    r::Ref{Any}
end
function unwrap2(rgid::GID, ref::Ref{Any})
    ref2 = get(ref)::Ref{Any}
    wait(ref2)
    rexec(rgid.proc, unwrap3, rgid, ref2)
end
function unwrap{R}(ref::Ref{Ref{R}})
    r = Ref{R}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref), unwrap2, rgid, ref)
    r::Ref{R}
end
function unwrap2{R}(rgid::GID, ref::Ref{Ref{R}})
    ref2 = get(ref)::Ref{R}
    wait(ref2)
    rexec(rgid.proc, unwrap3, rgid, ref2)
end
function unwrap3{R}(rgid::GID, ref2::Ref{R})
    r = getobj(rgid)::Ref{R}
    free(rgid)
    set_from_ref!(r, ref2)
end



function remote(ref::Ref, f::Callable, args...; R::Type=eltype(f))
    r = Ref{R}()
    rgid = makegid(r)
    @schedule rexec(getproc(ref), remote2, R, rgid, f, args)
    r::Ref{R}
end
function remote(p::Integer, f::Callable, args...; R::Type=eltype(f))
    r = Ref{R}()
    rgid = makegid(r)
    rexec(p, remote2, R, rgid, f, args)
    r::Ref{R}
end
function remote2(R::Type, rgid::GID, f::Callable, args)
    ref = Ref{R}(call(f, args...))
    rexec(rgid.proc, remote3, rgid, ref)
end
function remote3(rgid::GID, ref::Ref)
    r = getobj(rgid)
    free(rgid)
    set_from_ref!(r, ref)
end

macro remote(args...)
    if length(args) == 2
        (p, expr) = args
        resc(:(remote($p, ()->$expr)))
    elseif length(args) == 3
        (R, p, expr) = args
        resc(:(remote(R=$R, $p, ()->$expr)))
    else
        error("Expected: @remote [<type>] <proc> <expr>)")
    end
end



# Ref is Foldable, Functor, Applicative, and Monad

function freduce(op::Callable, zero, ref::Ref; R::Type=eltype(op))
    @rcall R ref call(op, zero, get(ref))
end
function freduce(op::Callable, zero, ref::Ref, ref2::Ref, refs::Ref...;
                 R::Type=eltype(op))
    @rcall R ref call(op, zero,
                      get(ref), get_remote(ref2), map(get_remote, refs)...)
end

function fmap(f::Callable, ref::Ref; R::Type=eltype(f))
    @remote R ref call(f, get(ref))
end
function fmap(f::Callable, ref::Ref, ref2::Ref, refs::Ref...; R::Type=eltype(f))
    @remote R ref call(f, get(ref), get_remote(ref2), map(get_remote, refs)...)
end

tycon{T,R}(::Type{Ref{T}}, ::Type{R}) = Ref{R}
valtype{T}(::Type{Ref{T}}) = T

munit{T}(::Type{Ref{T}}, x) = Ref{T}(x)
mjoin{T}(xss::Ref{Ref{T}}) = unwrap(xss)
mbind{T}(xs::Ref{T}, f::Callable; R::Type=eltype(f)) = mjoin(fmap(R=R, f, xs))

end
